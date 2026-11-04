import 'dart:math' as math;
import 'dart:typed_data';

import 'package:animestream/ui/models/widgets/subtitles/subtitle.dart';

import 'aac_parser.dart';
import 'h264_parser.dart';
import 'mkv_muxer.dart';
import 'subtitle_parser.dart';
import 'ts_demuxer.dart';

class _QueuedBlock {
  final int trackNumber;
  final List<int> data;
  final int pts;
  final int dts;
  final bool isKeyframe;

  _QueuedBlock(this.trackNumber, this.data, this.pts, this.dts, this.isKeyframe);
}

class _TimestampUnwrapper {
  int? _lastValue;
  int _wrapOffset = 0;

  int unwrap(int value) {
    if (_lastValue != null) {
      int diff = value - _lastValue!;
      if (diff < -0x100000000) {
        _wrapOffset += 0x200000000;
      } else if (diff > 0x100000000) {
        _wrapOffset -= 0x200000000;
      }
    }
    _lastValue = value;
    return value + _wrapOffset;
  }
}

/// A high-level class that orchestrates the conversion of TS chunks into a final MKV file.
class TsToMkvRemuxer {
  final TsDemuxer _videoDemuxer = TsDemuxer();
  final TsDemuxer _audioDemuxer = TsDemuxer();
  final H264Parser _h264Parser = H264Parser();
  final AacParser _aacParser = AacParser();
  final MkvMuxer _muxer;

  final bool hasSeparateAudio;
  final String? audioLanguage;
  final String? audioTrackName;

  bool _muxerOpened = false;
  final List<_QueuedBlock> _queue = [];
  int? _baseTimestamp;
  int? _firstVideoPts;
  int? _audioPtsOffset;

  final _videoPtsUnwrapper = _TimestampUnwrapper();
  final _videoDtsUnwrapper = _TimestampUnwrapper();
  final _audioPtsUnwrapper = _TimestampUnwrapper();
  final _audioDtsUnwrapper = _TimestampUnwrapper();

  final List<SubtitleCue> _subtitleCues = [];
  int _subtitleCueIndex = 0;

  String _subtitleCodecId = 'S_TEXT/UTF8';

  /// Provide the absolute path where the final MKV file should be saved.
  TsToMkvRemuxer(
    String outputPath, {
    this.hasSeparateAudio = false,
    this.audioLanguage,
    this.audioTrackName,
  }) : _muxer = MkvMuxer(outputPath);

  /// Load subtitles from a file (SRT or VTT)
  Future<void> loadSubtitles(String subtitlePath) async {
    final parsed = await SubtitleParser.parseFile(subtitlePath);
    _subtitleCues.addAll(parsed.cues);
    _subtitleCues.sort((a, b) => a.start.compareTo(b.start));
    _subtitleCodecId = parsed.codecId;
  }

  /// Load custom subtitles with a specific codec ID (e.g. D_WEBVTT/SUBTITLES)
  void loadCustomSubtitles(List<SubtitleCue> cues, {String codecId = 'D_WEBVTT/SUBTITLES'}) {
    _subtitleCues.addAll(cues);
    _subtitleCues.sort((a, b) => a.start.compareTo(b.start));
    _subtitleCodecId = codecId;
  }

  /// Feed video TS file bytes into the remuxer.
  Future<void> processVideoChunk(Uint8List videoBytes) async {
    final pesPackets = _videoDemuxer.process(videoBytes);

    for (final pes in pesPackets) {
      if (pes.streamType == 0x1B) {
        // H.264
        final frame = _h264Parser.processPes(pes.payload, pes.pts, pes.dts);
        if (frame != null && frame.lengthPrefixedData.isNotEmpty) {
          _firstVideoPts ??= frame.pts;
          int uPts = _videoPtsUnwrapper.unwrap(frame.pts);
          int uDts = _videoDtsUnwrapper.unwrap(frame.dts);
          _queue.add(_QueuedBlock(1, frame.lengthPrefixedData, uPts, uDts, frame.isKeyframe));
        }
      } else if (pes.streamType == 0x0F && !hasSeparateAudio) {
        // AAC inside video TS (single-stream mode)
        final frames = _aacParser.processPes(pes.payload, pes.pts, pes.dts);
        for (final f in frames) {
          int uPts = _audioPtsUnwrapper.unwrap(f.pts);
          int uDts = _audioDtsUnwrapper.unwrap(f.dts);
          _queue.add(_QueuedBlock(2, f.data, uPts, uDts, true));
        }
      }

      await _checkOpenMuxer();

      if (_muxerOpened && _queue.length > 200) {
        _flushQueue();
      }
    }
  }

  /// Feed audio bytes (raw ADTS AAC or MPEG-TS) into the remuxer.
  Future<void> processAudioChunk(Uint8List audioBytes) async {
    if (audioBytes.isEmpty) return;

    // Detect raw ADTS AAC: syncword 0xFFF (0xFF followed by high 4 bits 1)
    final isRawAac = audioBytes.length > 1 &&
        audioBytes[0] == 0xFF &&
        (audioBytes[1] & 0xF0) == 0xF0;

    if (isRawAac) {
      final frames = _aacParser.processPes(audioBytes, null, null);
      if (_audioPtsOffset == null && _firstVideoPts != null) {
        _audioPtsOffset = _firstVideoPts;
      }
      final offset = _audioPtsOffset ?? 0;

      for (final f in frames) {
        int uPts = _audioPtsUnwrapper.unwrap(f.pts + offset);
        int uDts = _audioDtsUnwrapper.unwrap(f.dts + offset);
        _queue.add(_QueuedBlock(2, f.data, uPts, uDts, true));
      }
    } else {
      final pesPackets = _audioDemuxer.process(audioBytes);
      for (final pes in pesPackets) {
        if (pes.streamType == 0x0F) {
          final frames = _aacParser.processPes(pes.payload, pes.pts, pes.dts);
          for (final f in frames) {
            int uPts = _audioPtsUnwrapper.unwrap(f.pts);
            int uDts = _audioDtsUnwrapper.unwrap(f.dts);
            _queue.add(_QueuedBlock(2, f.data, uPts, uDts, true));
          }
        }
      }
    }

    await _checkOpenMuxer();

    if (_muxerOpened && _queue.length > 200) {
      _flushQueue();
    }
  }

  /// Feed TS file bytes into the remuxer (backwards-compatible single-stream feed).
  Future<void> processChunk(Uint8List tsBytes) async {
    await processVideoChunk(tsBytes);
  }

  Future<void> _checkOpenMuxer() async {
    if (_muxerOpened) return;

    final avcc = _h264Parser.buildAvcc();
    final aacConfig = _aacParser.buildAudioSpecificConfig();

    final canOpen = avcc != null && (!hasSeparateAudio ? (aacConfig != null) : aacConfig != null);

    if (canOpen) {
      final sps = _h264Parser.spsInfo;
      final audioTracks = <MkvAudioTrack>[];
        audioTracks.add(
          MkvAudioTrack(
            trackNumber: 2,
            codecPrivate: aacConfig,
            sampleRate: _aacParser.getSamplingRate(),
            channels: _aacParser.getOutputChannels(),
            language: audioLanguage,
            name: audioTrackName,
            isDefault: true,
          ),
        );

      final subtitleTracks = <MkvSubtitleTrack>[];
      if (_subtitleCues.isNotEmpty) {
        subtitleTracks.add(
          MkvSubtitleTrack(
            trackNumber: audioTracks.isNotEmpty ? 3 : 2,
            codecId: _subtitleCodecId,
            isDefault: true,
          ),
        );
      }

      await _muxer.openWithTracks(
        avcc: avcc,
        audioTracks: audioTracks,
        subtitleTracks: subtitleTracks,
        width: sps?.width ?? 1920,
        height: sps?.height ?? 1080,
        fps: sps?.fps ?? 0.0,
      );
      _muxerOpened = true;
    }
  }

  void _flushQueue({bool forceAll = false}) {
    if (_queue.isEmpty) return;

    // Determine the true base timestamp from a healthy initial buffer
    if (_baseTimestamp == null) {
      _baseTimestamp = _queue.map((b) => math.min(b.pts, b.dts)).reduce(math.min);
    }

    _queue.sort((a, b) => a.dts.compareTo(b.dts));

    // When hasSeparateAudio is true and not forcing all, only flush blocks up to the
    // point where both video and audio have arrived to avoid writing one track far ahead.
    int flushUpToDts = 0x7FFFFFFFFFFFFFFF;
    if (hasSeparateAudio && !forceAll) {
      int? maxVideoDts;
      int? maxAudioDts;
      for (final b in _queue) {
        if (b.trackNumber == 1) {
          if (maxVideoDts == null || b.dts > maxVideoDts) maxVideoDts = b.dts;
        } else if (b.trackNumber == 2) {
          if (maxAudioDts == null || b.dts > maxAudioDts) maxAudioDts = b.dts;
        }
      }
      if (maxVideoDts != null && maxAudioDts != null) {
        flushUpToDts = math.min(maxVideoDts, maxAudioDts);
      } else {
        return; // Wait until both tracks have some frames queued
      }
    }

    final remaining = <_QueuedBlock>[];
    for (final block in _queue) {
      if (!forceAll && block.dts > flushUpToDts) {
        remaining.add(block);
        continue;
      }

      int adjPts = block.pts - _baseTimestamp!;
      if (adjPts < 0) adjPts = 0; // MKV timecodes cannot be negative
      int adjPtsMs = adjPts ~/ 90;

      while (_subtitleCueIndex < _subtitleCues.length) {
        final cue = _subtitleCues[_subtitleCueIndex];
        if (cue.start.inMilliseconds <= adjPtsMs) {
          int dur = cue.end.inMilliseconds - cue.start.inMilliseconds;
          _muxer.writeSubtitleBlock(3, cue.dialogue, cue.start.inMilliseconds, dur);
          _subtitleCueIndex++;
        } else {
          break;
        }
      }

      _muxer.writeBlock(block.trackNumber, block.data, adjPts, block.isKeyframe);
    }
    _queue.clear();
    _queue.addAll(remaining);
  }

  /// Flushes remaining buffers and securely closes the MKV file.
  /// Call this exactly once when the stream is fully downloaded/processed.
  Future<void> close() async {
    // Flush remaining video frames
    final lastVideo = _h264Parser.processPes(null, null, null);
    if (lastVideo != null && lastVideo.lengthPrefixedData.isNotEmpty) {
      int uPts = _videoPtsUnwrapper.unwrap(lastVideo.pts);
      int uDts = _videoDtsUnwrapper.unwrap(lastVideo.dts);
      _queue.add(_QueuedBlock(1, lastVideo.lengthPrefixedData, uPts, uDts, lastVideo.isKeyframe));
    }

    // Flush remaining audio frames
    final lastAudio = _aacParser.processPes(null, null, null);
    for (final a in lastAudio) {
      int uPts = _audioPtsUnwrapper.unwrap(a.pts);
      int uDts = _audioDtsUnwrapper.unwrap(a.dts);
      _queue.add(_QueuedBlock(2, a.data, uPts, uDts, true));
    }

    // Ensure muxer is opened before finishing
    if (!_muxerOpened) {
      final avcc = _h264Parser.buildAvcc();
      final aacConfig = _aacParser.buildAudioSpecificConfig();
      final sps = _h264Parser.spsInfo;

      final audioTracks = <MkvAudioTrack>[];
      if (aacConfig != null) {
        audioTracks.add(
          MkvAudioTrack(
            trackNumber: 2,
            codecPrivate: aacConfig,
            sampleRate: _aacParser.getSamplingRate(),
            channels: _aacParser.getOutputChannels(),
            language: audioLanguage,
            name: audioTrackName,
            isDefault: true,
          ),
        );
      }

      final subtitleTracks = <MkvSubtitleTrack>[];
      if (_subtitleCues.isNotEmpty) {
        subtitleTracks.add(
          MkvSubtitleTrack(
            trackNumber: audioTracks.isNotEmpty ? 3 : 2,
            codecId: _subtitleCodecId,
            isDefault: true,
          ),
        );
      }

      await _muxer.openWithTracks(
        avcc: avcc,
        audioTracks: audioTracks,
        subtitleTracks: subtitleTracks,
        width: sps?.width ?? 1920,
        height: sps?.height ?? 1080,
        fps: sps?.fps ?? 0.0,
      );
      _muxerOpened = true;
    }

    if (_muxerOpened) {
      _flushQueue(forceAll: true);

      while (_subtitleCueIndex < _subtitleCues.length) {
        final cue = _subtitleCues[_subtitleCueIndex];
        int dur = cue.end.inMilliseconds - cue.start.inMilliseconds;
        _muxer.writeSubtitleBlock(3, cue.dialogue, cue.start.inMilliseconds, dur);
        _subtitleCueIndex++;
      }

      await _muxer.close();
    }
  }
}
