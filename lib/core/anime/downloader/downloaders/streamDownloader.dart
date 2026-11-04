import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:animestream/core/anime/downloader/downloaders/baseDownloader.dart';
import 'package:animestream/core/anime/downloader/types.dart';
import 'package:animestream/core/commons/extensions.dart';
import 'package:animestream/core/commons/hlsParser/hlsParser.dart';
import 'package:animestream/core/commons/hlsParser/hlsSegment.dart';
import 'package:animestream/core/remuxer/remuxer.dart';
import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart';

class StreamDownloader extends BaseDownloader {
  StreamDownloader(DownloadTaskIsolate task) : super(task);

  final _encryptionKeyCache = <String, Uint8List>{};

  @override
  Future<void> download() async {
    await super.setUpPorts(task);

    final finalPath = await helper.makeDirectory(
      fileName: task.fileName,
      fileExtension: task.useMkvRemuxer ? "mkv" : "mp4",
      downloadPath: task.downloadPath,
    );

    File? output;
    TsToMkvRemuxer? remuxed;

    final hasAudio = task.audioStreams.isNotEmpty;

    if (task.useMkvRemuxer) {
      remuxed = TsToMkvRemuxer(
        finalPath,
        hasSeparateAudio: hasAudio,
        audioLanguage: task.audioStreams.firstOrNull?.language,
        audioTrackName: task.audioStreams.firstOrNull?.name,
      );
    } else {
      output = File(finalPath);
    }

    // Download subtitles if available
    if (task.subsUrl != null) {
      final downloadedSubsPath = await downloadSubs(task.subsUrl!, task.fileName, finalPath);
      if (task.writeSubtitleTrackToVideo && remuxed != null) {
        final ext = downloadedSubsPath.split(".").lastOrNull?.toLowerCase();
        if (ext == "srt" || ext == "vtt") {
          await remuxed.loadSubtitles(downloadedSubsPath);
        } else {
          task.sendPort?.send(
            DownloadMessage(
              status: 'error',
              id: task.id,
              message:
                  "Cannot write subtitles to the video file. Only SRT and VTT subtitles are supported by the remuxer.",
              extras: ["No stack trace needed btw... maybe.. the extension we got is: '$ext'"],
            ),
          );
        }
      }
    }

    // open the write mode
    final out = await output?.openWrite(mode: task.resumeFrom == 0 ? FileMode.write : FileMode.append);

    try {
      final streamBaseLink = helper.makeBaseLink(task.url);
      final audioBaseLink = hasAudio ? helper.makeBaseLink(task.audioStreams.first.url) : "";
      final segments = await HlsParser.parseSegments(task.url, customHeaders: task.customHeaders);
      final List<HlsSegment> audioSegements = task.audioStreams.isNotEmpty
          ? await HlsParser.parseSegments(task.audioStreams.first.url, customHeaders: task.customHeaders)
          : [];

      final parallelDownloadsBatchSize = task.parallelBatches;

      int lastUpdatedProgress = 0; // Dont notify if progress is same
      int lastDownloadedSegmentIndex = -1;

      final Map<int, BufferItem> buffers = {};
      final Map<int, BufferItem> audioBuffers = {};

      final Set<Future<void>> activeDownloads = {};
      final Set<Future<void>> activeAudioDownloads = {};

      int currentIndex = task.resumeFrom.toInt();
      int nextExpectedIndex = task.resumeFrom.toInt();
      final int totalSegments = segments.length;

      int currentAudioIndex = 0;
      int nextExpectedAudioIndex = 0;
      final int totalAudioSegments = audioSegements.length;

      // slot allocation
      final maxVideoBatch = parallelDownloadsBatchSize;
      final maxAudioBatch = hasAudio ? 2 : 0;
      final maxLookahead = maxVideoBatch * 2;

      Object? downloadError;

      while (nextExpectedIndex < totalSegments || (hasAudio && nextExpectedAudioIndex < totalAudioSegments)) {
        if (downloadError != null) {
          throw downloadError!;
        }

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

        if (hasAudio) {
          while (activeAudioDownloads.length < maxAudioBatch &&
              currentAudioIndex < totalAudioSegments &&
              (currentAudioIndex - nextExpectedAudioIndex) < maxLookahead) {
            final entryIndex = currentAudioIndex;
            final entry = audioSegements[currentAudioIndex];
            currentAudioIndex++;

            final future = () async {
              try {
                final segment = entry.url;
                final segmentNumber = entryIndex + 1;

                final uri = segment.startsWith('http') ? segment : "$audioBaseLink/$segment";

                final res = await helper.downloadSegmentWithRetries(
                  uri,
                  task.retryAttempts,
                  customHeaders: task.customHeaders,
                );

                if (status == DownloadStatus.cancelled) {
                  return;
                }

                if (res.statusCode >= 200 && res.statusCode < 300) {
                  // Decrypt if theres an encryption
                  final buffer = entry.encryptionKey != null
                      ? await _decryptSegment(buffer: res.bodyBytes, segment: entry)
                      : res.bodyBytes;
                  audioBuffers[entryIndex] = BufferItem(index: segmentNumber, buffer: buffer);
                } else {
                  print("Error for audio segment: $uri, body: ${res.body}, res head: ${res.headers}");
                  throw Exception("ERR_REQ_FAILED. Got Status: ${res.statusCode} for audio segment: $segmentNumber");
                }
              } catch (e) {
                downloadError = e;
              }
            }();

            activeAudioDownloads.add(future);
            future.whenComplete(() {
              activeAudioDownloads.remove(future);
            });
          }
        }

        // Limit the window lookahead to avoid unbounded memory usage if a single segment is too slow.
        // E.g., we allow fetching up to parallelDownloadsBatchSize * 2 segments ahead of the next expected one.
        // final maxLookahead = parallelDownloadsBatchSize * 2;

        // Fill the video window
        while (activeDownloads.length < parallelDownloadsBatchSize &&
            currentIndex < totalSegments &&
            (currentIndex - nextExpectedIndex) < maxLookahead) {
          final entryIndex = currentIndex;
          final entry = segments[currentIndex];
          currentIndex++;

          final future = () async {
            try {
              final segment = entry.url;
              final segmentNumber = currentIndex + 1;

              final uri = segment.startsWith('http') ? segment : "$streamBaseLink/$segment";

              final res = await helper.downloadSegmentWithRetries(
                uri,
                task.retryAttempts,
                customHeaders: task.customHeaders,
              );

              if (status == DownloadStatus.cancelled) {
                return;
              }

              if (res.statusCode >= 200 && res.statusCode < 300) {
                // Decrypt if theres an encryption
                final buffer = entry.encryptionKey != null
                    ? await _decryptSegment(buffer: res.bodyBytes, segment: entry)
                    : res.bodyBytes;
                buffers[entryIndex] = BufferItem(index: segmentNumber, buffer: buffer);
              } else {
                print("Error for segment: $uri, body: ${res.body}, res head: ${res.headers}");
                throw Exception("ERR_REQ_FAILED. Got Status: ${res.statusCode} for segment: $segmentNumber");
              }
            } catch (e) {
              downloadError = e;
            }
          }();

          activeDownloads.add(future);
          future.whenComplete(() {
            activeDownloads.remove(future);
          });
        }

        // Write sequential completed segments to file
        bool wroteSomething = false;

        // drain audio buffers first
        while (audioBuffers.containsKey(nextExpectedAudioIndex)) {
          if (!task.useMkvRemuxer) {
            throw Exception("Cannot write audio buffers to file without remuxer enabled.");
          }

          final b = audioBuffers.remove(nextExpectedAudioIndex)!;

          await remuxed?.processAudioChunk(b.buffer);

          nextExpectedAudioIndex++;
          // maybe in future add last downloaded aud segment here
          // lastDownloadedAudioSegmentIndex = nextExpectedAudioIndex;
          wroteSomething = true;
        }

        // then the video buffers
        while (buffers.containsKey(nextExpectedIndex)) {
          final b = buffers.remove(nextExpectedIndex)!;

          task.useMkvRemuxer ? await remuxed?.processVideoChunk(b.buffer) : out?.add(b.buffer);

          nextExpectedIndex++;
          lastDownloadedSegmentIndex = nextExpectedIndex;
          wroteSomething = true;
        }

        if (wroteSomething) {
          // Update progress
          final totalUnits = totalSegments + totalAudioSegments;
          final completedUnits = nextExpectedIndex + nextExpectedAudioIndex;
          final progress = totalUnits > 0 ? ((completedUnits / totalUnits) * 100).toInt() : 0;
          if (progress > lastUpdatedProgress && (progress - lastUpdatedProgress >= 2 || progress == 100)) {
            updateProgress(progress, finalPath);
            lastUpdatedProgress = progress;
          }
        }

        if (downloadError != null) {
          throw downloadError!;
        }

        // Wait for at least one download to complete if we didn't write anything and downloads are active
        if (!wroteSomething) {
          if (activeDownloads.isNotEmpty || activeAudioDownloads.isNotEmpty) {
            final allActive = [...activeDownloads, ...activeAudioDownloads];
            await Future.any(allActive.map((f) => f.catchError((_) {})));
          } else {
            await Future.delayed(const Duration(milliseconds: 30)); 
          }
        }
      }

      // send the completion/cancelled notification
      if (status.isCancelled) {
        await out?.close();
        await output?.delete();
        await remuxed?.close();

        super.setCancelledStatus();
      } else if (status.isPaused) {
      } // do nothing!
      else {
        await out?.close();
        await remuxed?.close();
        super.setCompletedStatus(finalPath);
      }

      print("[DOWNLOADER]<${task.id}> Closing download with state: ${status.name}");
    } catch (err) {
      // pack the bags and get out!
      print(err);
      await remuxed?.close();
      await out?.close();
      if (await output?.exists() ?? false) await output?.delete();

      //send download failed notification
      setFailedStatus(err.toString());
    }
  }

  Future<String> downloadSubs(String url, String fileName, String downloadPath) async {
    try {
      final folder = File(downloadPath).parent;
      fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '') + " Subtitles";

      final ext = url.split(".").lastOrNull ?? "txt";
      final file = File("${folder.path}${Platform.pathSeparator}$fileName.$ext");
      await file.writeAsString((await get(Uri.parse(url), headers: task.customHeaders)).body);
      return file.path;
    } catch (err) {
      print("[DOWNLOADER] Failed to download $fileName subs!");
      return "";
    }
  }

  Future<Uint8List> _decryptSegment({required Uint8List buffer, required HlsSegment segment}) async {
    try {
      // fetch the key, and cache it for future use
      final keyUri = segment.encryptionKey!.uri;
      Uint8List? keyBytes = _encryptionKeyCache[keyUri];

      if (keyBytes == null) {
        final res = await get(Uri.parse(keyUri), headers: task.customHeaders);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          keyBytes = res.bodyBytes;
          _encryptionKeyCache[keyUri] = keyBytes;
        } else {
          throw Exception("Failed to fetch encryption key from $keyUri. Status code: ${res.statusCode}");
        }
      }

      Uint8List ivBytes;
      if (segment.encryptionKey!.iv != null) {
        // Parse explicit IV from hex string (e.g., "0x00000000000000000000000000000001")
        final hexString = segment.encryptionKey!.iv!.replaceAll('0x', '').padLeft(32, '0');
        ivBytes = Uint8List.fromList(
          List.generate(16, (i) => int.parse(hexString.substring(i * 2, i * 2 + 2), radix: 16)),
        );
      } else {
        // Fallback: 16-byte big-endian integer of the sequence number
        ivBytes = Uint8List(16);
        final byteData = ByteData.view(ivBytes.buffer);
        byteData.setUint64(8, segment.sequenceNumber, Endian.big); // Writes to the last 8 bytes
      }

      final encrypt = Encrypter(AES(Key(keyBytes), mode: AESMode.cbc));
      final decryptedBuffer = encrypt.decryptBytes(Encrypted(buffer), iv: IV(ivBytes));
      return Uint8List.fromList(decryptedBuffer);
    } catch (err) {
      print("COULDNT DECRYPT A SEGMENT, KILLING THE DOWNLOAD");
      print(err.toString());
      rethrow;
    }
  }

  @override
  Future<void> onCancel() async {
    return; // nothing to do
  }
}
