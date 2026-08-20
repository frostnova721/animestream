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
  final TsDemuxer _demuxer = TsDemuxer();
  final H264Parser _h264Parser = H264Parser();
  final AacParser _aacParser = AacParser();
  final MkvMuxer _muxer;

  bool _muxerOpened = false;
  final List<_QueuedBlock> _queue = [];
  int? _baseTimestamp;

  final _videoPtsUnwrapper = _TimestampUnwrapper();
  final _videoDtsUnwrapper = _TimestampUnwrapper();
  final _audioPtsUnwrapper = _TimestampUnwrapper();
  final _audioDtsUnwrapper = _TimestampUnwrapper();

  final List<SubtitleCue> _subtitleCues = [];
  int _subtitleCueIndex = 0;

  String _subtitleCodecId = 'S_TEXT/UTF8';

  /// Provide the absolute path where the final MKV file should be saved.
  TsToMkvRemuxer(String outputPath) : _muxer = MkvMuxer(outputPath);

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

  /// Feed TS file bytes into the remuxer.
  /// You can call this method repeatedly as you download chunks of a stream.
  Future<void> processChunk(Uint8List tsBytes) async {
    final pesPackets = _demuxer.process(tsBytes);

    for (final pes in pesPackets) {
      if (pes.streamType == 0x1B) {
        // H.264
        final frame = _h264Parser.processPes(pes.payload, pes.pts, pes.dts);
        if (frame != null && frame.lengthPrefixedData.isNotEmpty) {
          int uPts = _videoPtsUnwrapper.unwrap(frame.pts);
          int uDts = _videoDtsUnwrapper.unwrap(frame.dts);
          _queue.add(_QueuedBlock(1, frame.lengthPrefixedData, uPts, uDts, frame.isKeyframe));
        }
      } else if (pes.streamType == 0x0F) {
        // AAC
        final frames = _aacParser.processPes(pes.payload, pes.pts, pes.dts);
        for (final f in frames) {
          int uPts = _audioPtsUnwrapper.unwrap(f.pts);
          int uDts = _audioDtsUnwrapper.unwrap(f.dts);
          _queue.add(_QueuedBlock(2, f.data, uPts, uDts, true));
        }
      }

      // Check if we have enough codec info to open the MKV file
      if (!_muxerOpened) {
        final avcc = _h264Parser.buildAvcc();
        final aacConfig = _aacParser.buildAudioSpecificConfig();

        if (avcc != null && aacConfig != null) {
          final sps = _h264Parser.spsInfo;
          await _muxer.open(
            avcc,
            aacConfig,
            _aacParser.getSamplingRate(),
            _aacParser.getOutputChannels(),
            width: sps?.width ?? 1920,
            height: sps?.height ?? 1080,
            fps: sps?.fps ?? 0.0,
            addSubtitleTrack: _subtitleCues.isNotEmpty,
            subtitleCodecId: _subtitleCodecId,
          );
          _muxerOpened = true;
        }
      }

      // Flush the queue periodically to keep memory usage low (buffer ~200 frames for sync analysis)
      if (_muxerOpened && _queue.length > 200) {
        _flushQueue();
      }
    }
  }

  void _flushQueue() {
    if (_queue.isEmpty) return;

    // Determine the true base timestamp from a healthy initial buffer
    if (_baseTimestamp == null) {
      _baseTimestamp = _queue.map((b) => math.min(b.pts, b.dts)).reduce(math.min);
    }

    _queue.sort((a, b) => a.dts.compareTo(b.dts));
    for (final block in _queue) {
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

    if (_muxerOpened) {
      _flushQueue();

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
