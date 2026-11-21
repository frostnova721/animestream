import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:animestream/core/commons/streams/mediaSegment.dart';
import 'package:animestream/core/commons/streams/streamRef.dart';
import 'package:animestream/core/downloader/downloaders/baseDownloader.dart';
import 'package:animestream/core/downloader/models.dart';
import 'package:animestream/core/commons/extensions.dart';
import 'package:animestream/core/remuxer/remuxer.dart';
import 'package:http/http.dart';

/// Downloads segmented streams (HLS or DASH, TS or fMP4) via their [StreamRef]s.
class StreamDownloader extends BaseDownloader {
  StreamDownloader(DownloadTaskIsolate task) : super(task);

  BaseMkvRemuxer? _remuxer;
  IOSink? _out;

  @override
  Future<void> download() async {
    await super.setUpPorts(task);

    final finalPath = await helper.makeDirectory(
      fileName: task.fileName,
      fileExtension: task.useMkvRemuxer ? "mkv" : "mp4",
      downloadPath: task.downloadPath,
    );

    File? output;

    try {
      final videoRef = task.videoStream?.ref ?? HlsRef(task.url);
      final audioRef = task.audioStreams.firstOrNull?.ref;

      final video = _Track(
        "video",
        await videoRef.segments(headers: task.customHeaders),
        maxParallel: task.parallelBatches,
        startAt: task.resumeFrom,
      );
      final audio = _Track("audio", await audioRef?.segments(headers: task.customHeaders) ?? const [], maxParallel: 2);
      final hasAudio = audio.segments.isNotEmpty;

      final protocol = switch (videoRef) {
        HlsRef() => "HLS (m3u8)",
        DashRef() => "DASH (mpd)",
      };
      log(
        "Stream: $protocol | video: ${_describeTrack(video.segments)}"
        "${hasAudio ? " | audio: ${_describeTrack(audio.segments)}" : " | audio: muxed in video"}"
        " | output: ${task.useMkvRemuxer ? "mkv (remuxed)" : "mp4 (raw concat)"}"
        "${task.resumeFrom > 0 ? " | resuming from segment ${task.resumeFrom}" : ""}",
      );

      if (hasAudio && !task.useMkvRemuxer) {
        throw Exception("Separate audio tracks can only be downloaded with the MKV remuxer enabled.");
      }

      if (task.useMkvRemuxer) {
        // Init segments mean fragmented MP4 (DASH, or HLS with #EXT-X-MAP), otherwise MPEG-TS
        final isFragmented = video.segments.any((s) => s.isInit) || audio.segments.any((s) => s.isInit);
        final audioInfo = task.audioStreams.firstOrNull;
        _remuxer = isFragmented
            ? M4sToMkvRemuxer(
                finalPath,
                hasSeparateAudio: hasAudio,
                audioLanguage: audioInfo?.language,
                audioTrackName: audioInfo?.name,
              )
            : TsToMkvRemuxer(
                finalPath,
                hasSeparateAudio: hasAudio,
                audioLanguage: audioInfo?.language,
                audioTrackName: audioInfo?.name,
              );
        log("Remuxer: ${_remuxer.runtimeType}");
      } else {
        output = File(finalPath);
        _out = output.openWrite(mode: task.resumeFrom == 0 ? FileMode.write : FileMode.append);
      }

      await _loadSubtitles(finalPath);

      // When resuming into a remuxer, it still needs the init segment that was skipped over
      final skippedInit = video.segments.take(video.nextToWrite).where((s) => s.isInit).lastOrNull;
      if (skippedInit != null && _remuxer != null) {
        final bytes = await _fetch(skippedInit, "video init", 0);
        if (bytes != null) await _write(skippedInit, bytes, isAudio: false);
      }

      final maxLookahead = task.parallelBatches * 2;
      int lastUpdatedProgress = 0; // Dont notify if progress is same
      int lastDownloadedSegmentIndex = -1;
      Object? downloadError;

      // Keep up to [maxParallel] fetches in flight, but never run too far ahead of the writer,
      // so a single slow segment can't make the buffers grow unbounded.
      void fill(_Track track) {
        while (track.active.length < track.maxParallel &&
            track.nextToFetch < track.segments.length &&
            (track.nextToFetch - track.nextToWrite) < maxLookahead) {
          final index = track.nextToFetch++;
          final future = () async {
            try {
              final bytes = await _fetch(track.segments[index], track.label, index);
              if (bytes != null) track.ready[index] = bytes;
            } catch (e) {
              downloadError ??= e;
            }
          }();
          track.active.add(future);
          future.whenComplete(() => track.active.remove(future));
        }
      }

      while (!video.isDone || !audio.isDone) {
        if (downloadError != null) throw downloadError!;

        // Handle commands
        if (status == DownloadStatus.cancelled) {
          break;
        } else if (status == DownloadStatus.paused) {
          if (completer != null && !completer!.isCompleted) {
            print("Already waiting. Skipping duplicate pause.");
            return;
          }
          setPausedStatus(lastUpdatedProgress, lastDownloadedSegmentIndex, finalPath);
          completer = Completer();
          try {
            timer = Timer(Duration(minutes: 1), () => completer!.completeError(Exception("Isolate wait timeout")));
            await completer!.future;
            completer = null;
            timer?.cancel();
            timer = null; // Kill the timer if resumed within the 1 minute window
          } catch (err) {
            print("Isolate wait timed out! \nError: ${err.toString()}");
            print("Self destructing isolate...");
            timer?.cancel(); // some gracefulness ?
            timer = null;
            completer = null;
            task.sendPort?.send(DownloadMessage(status: 'isolate_timeout', id: task.id));
            break;
          }
        }

        fill(audio);
        fill(video);

        // Write completed segments in order, audio first
        bool wroteSomething = false;

        while (audio.ready.containsKey(audio.nextToWrite)) {
          final segment = audio.segments[audio.nextToWrite];
          final bytes = audio.ready.remove(audio.nextToWrite)!;
          _logContainerOnce(audio, segment, bytes);
          await _write(segment, bytes, isAudio: true);
          audio.nextToWrite++;
          // maybe in future add last downloaded aud segment here
          wroteSomething = true;
        }

        while (video.ready.containsKey(video.nextToWrite)) {
          final segment = video.segments[video.nextToWrite];
          final bytes = video.ready.remove(video.nextToWrite)!;
          _logContainerOnce(video, segment, bytes);
          await _write(segment, bytes, isAudio: false);
          video.nextToWrite++;
          lastDownloadedSegmentIndex = video.nextToWrite;
          wroteSomething = true;
        }

        if (wroteSomething) {
          final totalUnits = video.segments.length + audio.segments.length;
          final completedUnits = video.nextToWrite + audio.nextToWrite;
          final progress = totalUnits > 0 ? ((completedUnits / totalUnits) * 100).toInt() : 0;
          if (progress > lastUpdatedProgress && (progress - lastUpdatedProgress >= 2 || progress == 100)) {
            updateProgress(progress, finalPath);
            lastUpdatedProgress = progress;
          }
        }

        if (downloadError != null) throw downloadError!;

        // Wait for at least one download to complete if we didn't write anything and downloads are active
        if (!wroteSomething) {
          final allActive = [...video.active, ...audio.active];
          if (allActive.isNotEmpty) {
            await Future.any(allActive.map((f) => f.catchError((_) {})));
          } else {
            await Future.delayed(const Duration(milliseconds: 30));
          }
        }
      }

      // send the completion/cancelled notification
      if (status.isCancelled) {
        await _out?.close();
        await output?.delete();
        await _remuxer?.close();

        super.setCancelledStatus();
      } else if (status.isPaused) {
      } // do nothing!
      else {
        await _out?.close();
        await _remuxer?.close();
        super.setCompletedStatus(finalPath);
      }

      print("[DOWNLOADER]<${task.id}> Closing download with state: ${status.name}");
    } catch (err) {
      // pack the bags and get out!
      print(err);
      await _remuxer?.close();
      await _out?.close();
      if (await output?.exists() ?? false) await output?.delete();

      //send download failed notification
      setFailedStatus(err.toString());
    }
  }

  /// Downloads and prepares (decrypts etc.) a segment. Returns null if the download got cancelled meanwhile.
  Future<Uint8List?> _fetch(MediaSegment segment, String label, int index) async {
    final res = await helper.downloadSegmentWithRetries(
      segment.url,
      task.retryAttempts,
      cancel: cancelSignal,
      customHeaders: {
        ...task.customHeaders,
        if (segment.byteRange != null) 'Range': rangeHeaderValue(segment.byteRange!),
      },
    );

    if (status == DownloadStatus.cancelled) return null;

    if (res.statusCode < 200 || res.statusCode >= 300) {
      print("Error for $label segment: ${segment.url}, body: ${res.body}, res head: ${res.headers}");
      throw Exception("ERR_REQ_FAILED. Got Status: ${res.statusCode} for $label segment: ${index + 1}");
    }

    return segment.prepare(res.bodyBytes, headers: task.customHeaders);
  }

  /// Summary of a track from its segment list, e.g. "412 segments, fMP4 (init + .m4s)".
  String _describeTrack(List<MediaSegment> segments) {
    final media = segments.where((s) => !s.isInit);
    final ext = _extensionOf(media.firstOrNull?.url);
    final hasInit = segments.any((s) => s.isInit);
    final ranged = media.any((s) => s.byteRange != null);
    final kind = hasInit ? "fMP4 (init + $ext)" : ext;
    return "${media.length} segments, $kind${ranged ? ", byte-ranged" : ""}";
  }

  /// Logs what the first media segment of a track actually contains, judged from its bytes.
  /// URL extensions are unreliable: plenty of CDNs serve TS segments as .jpg/.png/.html.
  void _logContainerOnce(_Track track, MediaSegment segment, Uint8List bytes) {
    if (track.containerLogged || segment.isInit) return;
    track.containerLogged = true;
    log("${track.label} segments contain: ${_sniffContainer(bytes)} (url says ${_extensionOf(segment.url)})");
  }

  static String _sniffContainer(Uint8List b) {
    // MPEG-TS: 0x47 sync byte every 188 bytes
    if (b.isNotEmpty && b[0] == 0x47 && (b.length < 189 || b[188] == 0x47)) return "MPEG-TS";
    // ISO BMFF: [size:4][type:4], media fragments start with styp/moof (sidx/ftyp also seen)
    if (b.length >= 8) {
      final type = String.fromCharCodes(b.sublist(4, 8));
      if (const {'styp', 'moof', 'sidx', 'ftyp', 'emsg', 'prft'}.contains(type))
        return "fMP4 (m4s, starts with '$type')";
    }
    // ADTS AAC: 12-bit 0xFFF sync word
    if (b.length >= 2 && b[0] == 0xFF && (b[1] & 0xF6) == 0xF0) return "raw AAC (ADTS)";
    if (b.length >= 3 && b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) return "ID3-prefixed (likely raw AAC/TS)";
    final head = b.take(8).map((x) => x.toRadixString(16).padLeft(2, '0')).join(' ');
    return "unknown (first bytes: $head)";
  }

  static String _extensionOf(String? url) {
    if (url == null) return "none";
    final path = Uri.tryParse(url)?.path ?? url;
    final last = path.split('/').last;
    return last.contains('.') ? ".${last.split('.').last.toLowerCase()}" : "no extension";
  }

  /// Routes a segment to the remuxer (init vs media, audio vs video) or straight to the output file.
  Future<void> _write(MediaSegment segment, Uint8List bytes, {required bool isAudio}) async {
    final remuxer = _remuxer;

    // Without a remuxer, init + fragments concatenated is itself a valid (fragmented) mp4
    if (remuxer == null) {
      _out?.add(bytes);
      return;
    }

    if (segment.isInit) {
      if (remuxer is M4sToMkvRemuxer) {
        isAudio ? await remuxer.processAudioInit(bytes) : await remuxer.processVideoInit(bytes);
      }
      return;
    }

    isAudio ? await remuxer.processAudioChunk(bytes) : await remuxer.processVideoChunk(bytes);
  }

  Future<void> _loadSubtitles(String finalPath) async {
    if (task.subsUrl == null || task.subsUrl!.isEmpty) return;

    final downloadedSubsPath = await downloadSubs(task.subsUrl!, task.fileName, finalPath);
    if (!task.writeSubtitleTrackToVideo || _remuxer == null) return;

    final ext = downloadedSubsPath.split(".").lastOrNull?.toLowerCase();
    if (ext == "srt" || ext == "vtt") {
      await _remuxer!.loadSubtitles(downloadedSubsPath);
    } else {
      task.sendPort?.send(
        DownloadMessage(
          status: 'error',
          id: task.id,
          message: "Cannot write subtitles to the video file. Only SRT and VTT subtitles are supported by the remuxer.",
          extras: ["Subtitle URL: ${task.subsUrl} , Extension is $ext"],
        ),
      );
    }
  }

  Future<String> downloadSubs(String url, String fileName, String downloadPath) async {
    try {
      final folder = File(downloadPath).parent;
      fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '') + " Subtitles";

      final res = await get(Uri.parse(url), headers: task.customHeaders);
      final ext = await detectSubtitleFormat(utf8.decode(res.bodyBytes)) ?? "txt";
      final file = File("${folder.path}${Platform.pathSeparator}$fileName.$ext");
      await file.writeAsString(utf8.decode(res.bodyBytes));
      return file.path;
    } catch (err) {
      print("[DOWNLOADER] Failed to download $fileName subs!");
      return "";
    }
  }

  String? detectSubtitleFormat(String body) {
    final head = body.replaceFirst('\uFEFF', '').trimLeft(); // strip BOM + leading blank lines
    final start = head.length > 2000 ? head.substring(0, 2000) : head;

    if (start.startsWith('WEBVTT')) return "vtt";
    if (start.contains('[Script Info]') || start.contains('[Events]')) return "ass";
    if (RegExp(r'\d{2}:\d{2}:\d{2},\d{3}\s*-->').hasMatch(start)) return "srt"; // comma = SRT
    if (RegExp(r'(\d{2}:)?\d{2}:\d{2}\.\d{3}\s*-->').hasMatch(start)) return "vtt"; // dot, header missing
    return null;
  }

  @override
  Future<void> onCancel() async {
    return; // nothing to do
  }
}

/// Download/write bookkeeping for one track's segments.
class _Track {
  final String label;
  final List<MediaSegment> segments;
  final int maxParallel;

  /// Downloaded segments waiting to be written in order, by index
  final Map<int, Uint8List> ready = {};
  final Set<Future<void>> active = {};

  int nextToFetch;
  int nextToWrite;

  bool containerLogged = false;

  _Track(this.label, this.segments, {required this.maxParallel, int startAt = 0})
    : nextToFetch = startAt,
      nextToWrite = startAt;

  bool get isDone => nextToWrite >= segments.length;
}
