import 'dart:convert';
import 'dart:io';

import 'ebml.dart';

class CuePoint {
  final int timecode;
  final int clusterPos;

  CuePoint(this.timecode, this.clusterPos);
}

class MkvMuxer {
  final File _outputFile;
  RandomAccessFile? _file;

  int _clusterTimecode = -1;
  int _maxTimecodeMs = 0;
  int _durationPosition = -1;
  int _segmentSizePosition = -1;
  int _segmentDataStart = -1;
  int _currentClusterPos = -1;
  int _seekHeadPosition = -1;
  int _currentClusterSizePosition = -1;

  final List<CuePoint> _cues = [];

  MkvMuxer(String path) : _outputFile = File(path);

  Future<void> open(
    List<int>? avcc,
    List<int>? audioConfig,
    double audioSampleRate,
    int audioChannels, {
    int width = 1920,
    int height = 1080,
    double fps = 0.0,
    bool addSubtitleTrack = false,
    String subtitleCodecId = 'S_TEXT/UTF8',
  }) async {
    _file = await _outputFile.open(mode: FileMode.write);

    // 1. EBML Header
    _file!.writeFromSync(
      Ebml.writeData(0x1A45DFA3, [
        ...Ebml.writeUint(0x4286, 1),
        ...Ebml.writeUint(0x42F7, 1),
        ...Ebml.writeUint(0x42F2, 4),
        ...Ebml.writeUint(0x42F3, 8),
        ...Ebml.writeString(0x4282, 'matroska'),
        ...Ebml.writeUint(0x4287, 4),
        ...Ebml.writeUint(0x4285, 2),
      ]),
    );

    // 2. Segment
    _file!.writeFromSync(Ebml.writeId(0x18538067));
    _segmentSizePosition = _file!.positionSync();
    _file!.writeFromSync([0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);

    _segmentDataStart = _file!.positionSync();

    // 2.5 SeekHead (Placeholder)
    _seekHeadPosition = _file!.positionSync();
    _file!.writeFromSync([0xEC, 0x80 | 62]);
    _file!.writeFromSync(List.filled(62, 0));

    // 3. Segment Info
    final infoData = <int>[
      ...Ebml.writeUint(0x2AD7B1, 1000000), // TimecodeScale = 1ms
      ...Ebml.writeString(0x4D80, 'StreaMux'),
      ...Ebml.writeString(0x5741, 'A CERTAIN GOATED APP'),
    ];

    _file!.writeFromSync(Ebml.writeId(0x1549A966));
    _file!.writeFromSync(Ebml.writeVint(infoData.length + 11));
    _file!.writeFromSync(infoData);

    _durationPosition = _file!.positionSync();
    _file!.writeFromSync(Ebml.writeFloat(0x4489, 0.0));

    // 4. Tracks
    final tracksData = <int>[];

    if (avcc != null) {
      final videoTrackData = <int>[
        ...Ebml.writeUint(0xD7, 1),
        ...Ebml.writeUint(0x73C5, 1),
        ...Ebml.writeUint(0x83, 1),
        ...Ebml.writeString(0x86, 'V_MPEG4/ISO/AVC'),
      ];

      if (fps > 0) {
        int defaultDurationNs = (1000000000 / fps).round();
        videoTrackData.addAll(Ebml.writeUint(0x23E383, defaultDurationNs));
      }

      videoTrackData.addAll(Ebml.writeData(0x63A2, avcc));
      videoTrackData.addAll(Ebml.writeData(0xE0, [...Ebml.writeUint(0xB0, width), ...Ebml.writeUint(0xBA, height)]));

      tracksData.addAll(Ebml.writeData(0xAE, videoTrackData));
    }

    if (audioConfig != null) {
      tracksData.addAll(
        Ebml.writeData(0xAE, [
          ...Ebml.writeUint(0xD7, 2),
          ...Ebml.writeUint(0x73C5, 2),
          ...Ebml.writeUint(0x83, 2),
          ...Ebml.writeString(0x86, 'A_AAC'),
          ...Ebml.writeData(0x63A2, audioConfig),
          ...Ebml.writeData(0xE1, [...Ebml.writeFloat(0xB5, audioSampleRate), ...Ebml.writeUint(0x9F, audioChannels)]),
        ]),
      );
    }

    if (addSubtitleTrack) {
      tracksData.addAll(
        Ebml.writeData(0xAE, [
          ...Ebml.writeUint(0xD7, 3), // TrackNumber
          ...Ebml.writeUint(0x73C5, 3), // TrackUID
          ...Ebml.writeUint(0x83, 0x11), // TrackType Subtitle
          ...Ebml.writeString(0x86, subtitleCodecId),
        ]),
      );
    }

    _file!.writeFromSync(Ebml.writeData(0x1654AE6B, tracksData));
  }

  void writeBlock(int trackNumber, List<int> data, int pts90k, bool isKeyframe) {
    if (_file == null) return;

    int timecodeMs = pts90k ~/ 90;
    if (timecodeMs > _maxTimecodeMs) {
      _maxTimecodeMs = timecodeMs;
    }

    int relativeTime = timecodeMs - _clusterTimecode;

    // Create a new cluster if:
    // 1. It's the first cluster
    // 2. The block is > 5000ms ahead of the cluster start
    // 3. The block is < -30000ms behind the cluster start (MKV max is -32768)
    if (_clusterTimecode == -1 || relativeTime > 5000 || relativeTime < -30000) {
      _patchCurrentClusterSize();

      _currentClusterPos = _file!.positionSync() - _segmentDataStart;

      _file!.writeFromSync(Ebml.writeId(0x1F43B675));
      _currentClusterSizePosition = _file!.positionSync();
      _file!.writeFromSync([0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);

      _clusterTimecode = timecodeMs;
      _file!.writeFromSync(Ebml.writeUint(0xE7, _clusterTimecode));
      relativeTime = 0;
    }

    if (trackNumber == 1 && isKeyframe) {
      if (_cues.isEmpty || timecodeMs - _cues.last.timecode > 1000) {
        _cues.add(CuePoint(timecodeMs, _currentClusterPos));
      }
    }

    if (relativeTime < -32768) relativeTime = -32768;
    if (relativeTime > 32767) relativeTime = 32767;

    int flags = isKeyframe ? 0x80 : 0x00;

    final blockData = <int>[
      ...Ebml.writeVint(trackNumber),
      (relativeTime >> 8) & 0xFF,
      relativeTime & 0xFF,
      flags,
      ...data,
    ];

    _file!.writeFromSync(Ebml.writeData(0xA3, blockData));
  }

  void writeSubtitleBlock(int trackNumber, String text, int timecodeMs, int durationMs) {
    if (_file == null) return;

    if (timecodeMs > _maxTimecodeMs) {
      _maxTimecodeMs = timecodeMs;
    }

    int relativeTime = timecodeMs - _clusterTimecode;

    if (_clusterTimecode == -1 || relativeTime > 5000 || relativeTime < -30000) {
      _patchCurrentClusterSize();

      _currentClusterPos = _file!.positionSync() - _segmentDataStart;

      _file!.writeFromSync(Ebml.writeId(0x1F43B675));
      _currentClusterSizePosition = _file!.positionSync();
      _file!.writeFromSync([0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);

      _clusterTimecode = timecodeMs;
      _file!.writeFromSync(Ebml.writeUint(0xE7, _clusterTimecode));
      relativeTime = 0;
    }

    if (relativeTime < -32768) relativeTime = -32768;
    if (relativeTime > 32767) relativeTime = 32767;

    final textBytes = utf8.encode(text);
    
    final blockData = <int>[
      ...Ebml.writeVint(trackNumber),
      (relativeTime >> 8) & 0xFF,
      relativeTime & 0xFF,
      0x00, // flags
      ...textBytes,
    ];

    final blockGroupData = <int>[
      ...Ebml.writeData(0xA1, blockData),
      ...Ebml.writeUint(0x9B, durationMs),
    ];

    _file!.writeFromSync(Ebml.writeData(0xA0, blockGroupData));
  }

  void _patchCurrentClusterSize() {
    if (_currentClusterSizePosition != -1 && _file != null) {
      int currentPos = _file!.positionSync();
      int clusterSize = currentPos - _currentClusterSizePosition - 8;

      _file!.setPositionSync(_currentClusterSizePosition);
      _file!.writeFromSync([
        0x01,
        (clusterSize >> 48) & 0xFF,
        (clusterSize >> 40) & 0xFF,
        (clusterSize >> 32) & 0xFF,
        (clusterSize >> 24) & 0xFF,
        (clusterSize >> 16) & 0xFF,
        (clusterSize >> 8) & 0xFF,
        clusterSize & 0xFF,
      ]);
      _file!.setPositionSync(currentPos);
    }
  }

  Future<void> close() async {
    if (_file != null) {
      _patchCurrentClusterSize();
      int cuesStartPos = -1;

      // Write Cues element at the end
      if (_cues.isNotEmpty) {
        cuesStartPos = _file!.positionSync() - _segmentDataStart;
        final cuesData = <int>[];
        for (final cue in _cues) {
          final cueTrackPositions = Ebml.writeData(0xB7, [
            ...Ebml.writeUint(0xF7, 1),
            ...Ebml.writeUint(0xF1, cue.clusterPos),
          ]);

          cuesData.addAll(Ebml.writeData(0xBB, [...Ebml.writeUint(0xB3, cue.timecode), ...cueTrackPositions]));
        }

        _file!.writeFromSync(Ebml.writeData(0x1C53BB6B, cuesData));
      }

      int fileLength = await _file!.length();

      // Seek back and write SeekHead pointing to Cues
      if (_seekHeadPosition != -1 && cuesStartPos != -1) {
        await _file!.setPosition(_seekHeadPosition);

        final seekElement = Ebml.writeData(0x4DBB, [
          ...Ebml.writeData(0x53AB, [0x1C, 0x53, 0xBB, 0x6B]), // Cues ID
          ...Ebml.writeUint(0x53AC, cuesStartPos),
        ]);

        final seekHead = Ebml.writeData(0x114D9B74, seekElement);
        _file!.writeFromSync(seekHead);

        // Pad remaining reserved space with Void
        int remaining = 64 - seekHead.length;
        if (remaining >= 2) {
          _file!.writeFromSync([0xEC]);
          // Calculate VINT for remaining - 2
          int voidSize = remaining - 2; // Assume voidSize < 127
          _file!.writeFromSync([0x80 | voidSize]);
          if (voidSize > 0) {
            _file!.writeFromSync(List.filled(voidSize, 0));
          }
        }
      }

      // Seek back and update Duration
      if (_durationPosition != -1 && _maxTimecodeMs > 0) {
        await _file!.setPosition(_durationPosition);
        _file!.writeFromSync(Ebml.writeFloat(0x4489, _maxTimecodeMs.toDouble()));
      }

      // Seek back and update Segment Size
      if (_segmentSizePosition != -1 && _segmentDataStart != -1) {
        int segmentDataSize = fileLength - _segmentDataStart;
        await _file!.setPosition(_segmentSizePosition);

        _file!.writeFromSync([
          0x01,
          (segmentDataSize >> 48) & 0xFF,
          (segmentDataSize >> 40) & 0xFF,
          (segmentDataSize >> 32) & 0xFF,
          (segmentDataSize >> 24) & 0xFF,
          (segmentDataSize >> 16) & 0xFF,
          (segmentDataSize >> 8) & 0xFF,
          segmentDataSize & 0xFF,
        ]);
      }

      await _file!.close();
      _file = null;
    }
  }
}
