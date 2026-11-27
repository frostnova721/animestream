import 'dart:math' as math;
import 'dart:typed_data';

import 'package:animestream/core/commons/subtitleParsers/subtitle.dart';

import 'mkv_muxer.dart';
import 'subtitle_parser.dart';

class QueuedBlock {
  final int trackNumber;
  final List<int> data;
  final int pts;
  final int dts;
  final bool isKeyframe;

  QueuedBlock(this.trackNumber, this.data, this.pts, this.dts, this.isKeyframe);
}

class TimestampUnwrapper {
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

/// Abstract base class for remuxers that write audio, video, and subtitles into an MKV container.
///
/// Encapsulates queue management, DTS interleaving, timestamp unwrapping, and subtitle synchronization.
abstract class BaseMkvRemuxer {
  final MkvMuxer muxer;
  final bool hasSeparateAudio;
  final String? audioLanguage;
  final String? audioTrackName;

  bool muxerOpened = false;
  final List<QueuedBlock> queue = [];
  int? baseTimestamp;

  final videoPtsUnwrapper = TimestampUnwrapper();
  final videoDtsUnwrapper = TimestampUnwrapper();
  final audioPtsUnwrapper = TimestampUnwrapper();
  final audioDtsUnwrapper = TimestampUnwrapper();

  final List<SubtitleCue> subtitleCues = [];
  int subtitleCueIndex = 0;
  String subtitleCodecId = 'S_TEXT/UTF8';

  BaseMkvRemuxer(
    String outputPath, {
    this.hasSeparateAudio = false,
    this.audioLanguage,
    this.audioTrackName,
  }) : muxer = MkvMuxer(outputPath);

  /// Load subtitles from an SRT or VTT file on disk.
  Future<void> loadSubtitles(String subtitlePath) async {
    final parsed = await SubtitleParser.parseFile(subtitlePath);
    subtitleCues.addAll(parsed.cues);
    subtitleCues.sort((a, b) => a.start.compareTo(b.start));
    subtitleCodecId = parsed.codecId;
  }

  /// Load custom subtitle cues with a specific codec ID (e.g. D_WEBVTT/SUBTITLES).
  void loadCustomSubtitles(List<SubtitleCue> cues, {String codecId = 'D_WEBVTT/SUBTITLES'}) {
    subtitleCues.addAll(cues);
    subtitleCues.sort((a, b) => a.start.compareTo(b.start));
    subtitleCodecId = codecId;
  }

  /// Feed video chunk bytes into the remuxer.
  Future<void> processVideoChunk(Uint8List videoBytes);

  /// Feed audio chunk bytes into the remuxer.
  Future<void> processAudioChunk(Uint8List audioBytes);

  /// Feed chunk bytes into the remuxer (backwards-compatible single-stream feed).
  Future<void> processChunk(Uint8List bytes) async {
    await processVideoChunk(bytes);
  }

  /// Flushes remaining buffers and securely closes the MKV file.
  Future<void> close();

  /// Adds a frame to the queue, unwrapping timestamps if needed.
  void queueBlock(int trackNumber, List<int> data, int pts, int dts, bool isKeyframe) {
    queue.add(QueuedBlock(trackNumber, data, pts, dts, isKeyframe));
  }

  /// Sorts and flushes queued blocks into the MKV muxer, interleaving tracks and subtitles.
  void flushQueue({bool forceAll = false}) {
    if (queue.isEmpty) return;

    if (baseTimestamp == null) {
      baseTimestamp = queue.map((b) => math.min(b.pts, b.dts)).reduce(math.min);
    }

    queue.sort((a, b) => a.dts.compareTo(b.dts));

    int flushUpToDts = 0x7FFFFFFFFFFFFFFF;
    if (hasSeparateAudio && !forceAll) {
      int? maxVideoDts;
      int? maxAudioDts;
      for (final b in queue) {
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

    final remaining = <QueuedBlock>[];
    for (final block in queue) {
      if (!forceAll && block.dts > flushUpToDts) {
        remaining.add(block);
        continue;
      }

      int adjPts = block.pts - baseTimestamp!;
      if (adjPts < 0) adjPts = 0; // MKV timecodes cannot be negative
      int adjPtsMs = adjPts ~/ 90;

      while (subtitleCueIndex < subtitleCues.length) {
        final cue = subtitleCues[subtitleCueIndex];
        if (cue.start.inMilliseconds <= adjPtsMs) {
          int dur = cue.end.inMilliseconds - cue.start.inMilliseconds;
          muxer.writeSubtitleBlock(3, cue.dialogue, cue.start.inMilliseconds, dur);
          subtitleCueIndex++;
        } else {
          break;
        }
      }

      muxer.writeBlock(block.trackNumber, block.data, adjPts, block.isKeyframe);
    }
    queue.clear();
    queue.addAll(remaining);
  }

  /// Finalizes any remaining subtitles and closes the underlying MKV file.
  Future<void> finalizeMuxer() async {
    if (muxerOpened) {
      flushQueue(forceAll: true);

      while (subtitleCueIndex < subtitleCues.length) {
        final cue = subtitleCues[subtitleCueIndex];
        int dur = cue.end.inMilliseconds - cue.start.inMilliseconds;
        muxer.writeSubtitleBlock(3, cue.dialogue, cue.start.inMilliseconds, dur);
        subtitleCueIndex++;
      }

      await muxer.close();
    }
  }
}
