import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'ebml.dart';

class CuePoint {
  final int timecode;
  final int clusterPos;

  CuePoint(this.timecode, this.clusterPos);
}

/// Represents an audio track configuration in the MKV container.
class MkvAudioTrack {
  final int trackNumber;
  final int? trackUid;
  final List<int>? codecPrivate; // e.g., AudioSpecificConfig for AAC
  final double sampleRate;
  final int channels;
  final String codecId;
  final String? name; // e.g. "Japanese (Original)", "English (Dub)"
  final String? language; // ISO 639-2 language code, e.g. "jpn", "eng"
  final bool isDefault;

  MkvAudioTrack({
    required this.trackNumber,
    this.trackUid,
    this.codecPrivate,
    this.sampleRate = 44100.0,
    this.channels = 2,
    this.codecId = 'A_AAC',
    this.name,
    this.language,
    this.isDefault = false,
  });
}

/// Represents a subtitle track configuration in the MKV container.
class MkvSubtitleTrack {
  final int trackNumber;
  final int? trackUid;
  final String codecId; // e.g. 'S_TEXT/UTF8', 'D_WEBVTT/SUBTITLES'
  final String? name;
  final String? language;
  final bool isDefault;

  MkvSubtitleTrack({
    required this.trackNumber,
    this.trackUid,
    this.codecId = 'S_TEXT/UTF8',
    this.name,
    this.language,
    this.isDefault = false,
  });
}

class MkvMuxer {
  final File _outputFile;
  RandomAccessFile? _file;

  int _videoTrackNumber = 1;
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

  static String _toIso639_2(String lang) {
    final l = lang.trim().toLowerCase();
    if (l.length == 3) return l;
    const map = {
      'ja': 'jpn',
      'jp': 'jpn',
      'japanese': 'jpn',
      'en': 'eng',
      'english': 'eng',
      'es': 'spa',
      'spanish': 'spa',
      'fr': 'fra',
      'french': 'fra',
      'de': 'deu',
      'german': 'deu',
      'it': 'ita',
      'italian': 'ita',
      'pt': 'por',
      'portuguese': 'por',
      'ru': 'rus',
      'russian': 'rus',
      'zh': 'zho',
      'chinese': 'zho',
      'ko': 'kor',
      'korean': 'kor',
      'ar': 'ara',
      'arabic': 'ara',
      'hi': 'hin',
      'hindi': 'hin',
    };
    return map[l] ?? (l.length >= 3 ? l.substring(0, 3) : 'und');
  }

  List<int> _buildAudioTrackEntry(MkvAudioTrack track) {
    final entry = <int>[
      ...Ebml.writeUint(0xD7, track.trackNumber),
      ...Ebml.writeUint(0x73C5, track.trackUid ?? track.trackNumber),
      ...Ebml.writeUint(0x83, 2), // TrackType Audio
      ...Ebml.writeUint(0x88, track.isDefault ? 1 : 0), // FlagDefault
      ...Ebml.writeString(0x86, track.codecId),
    ];

    if (track.name != null && track.name!.isNotEmpty) {
      entry.addAll(Ebml.writeString(0x536E, track.name!));
    }
    if (track.language != null && track.language!.isNotEmpty) {
      entry.addAll(Ebml.writeString(0x22B59C, _toIso639_2(track.language!)));
    }
    if (track.codecPrivate != null && track.codecPrivate!.isNotEmpty) {
      entry.addAll(Ebml.writeData(0x63A2, track.codecPrivate!));
    }

    final audioSettings = <int>[
      ...Ebml.writeFloat(0xB5, track.sampleRate),
      ...Ebml.writeUint(0x9F, track.channels),
    ];
    entry.addAll(Ebml.writeData(0xE1, audioSettings));

    return Ebml.writeData(0xAE, entry);
  }

  List<int> _buildSubtitleTrackEntry(MkvSubtitleTrack track) {
    final entry = <int>[
      ...Ebml.writeUint(0xD7, track.trackNumber),
      ...Ebml.writeUint(0x73C5, track.trackUid ?? track.trackNumber),
      ...Ebml.writeUint(0x83, 0x11), // TrackType Subtitle
      ...Ebml.writeUint(0x88, track.isDefault ? 1 : 0), // FlagDefault
      ...Ebml.writeString(0x86, track.codecId),
    ];

    if (track.name != null && track.name!.isNotEmpty) {
      entry.addAll(Ebml.writeString(0x536E, track.name!));
    }
    if (track.language != null && track.language!.isNotEmpty) {
      entry.addAll(Ebml.writeString(0x22B59C, _toIso639_2(track.language!)));
    }

    return Ebml.writeData(0xAE, entry);
  }

  /// Opens the MKV container with explicit audio and subtitle track configurations.
  Future<void> openWithTracks({
    List<int>? avcc,
    int videoTrackNumber = 1,
    int? videoTrackUid,
    String? videoTrackName,
    String? videoLanguage,
    int width = 1920,
    int height = 1080,
    double fps = 0.0,
    List<MkvAudioTrack> audioTracks = const [],
    List<MkvSubtitleTrack> subtitleTracks = const [],
  }) async {
    _videoTrackNumber = videoTrackNumber;
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
        ...Ebml.writeUint(0xD7, videoTrackNumber),
        ...Ebml.writeUint(0x73C5, videoTrackUid ?? videoTrackNumber),
        ...Ebml.writeUint(0x83, 1), // TrackType Video
        ...Ebml.writeUint(0x88, 1), // FlagDefault = 1
        ...Ebml.writeString(0x86, 'V_MPEG4/ISO/AVC'),
      ];

      if (videoTrackName != null && videoTrackName.isNotEmpty) {
        videoTrackData.addAll(Ebml.writeString(0x536E, videoTrackName));
      }
      if (videoLanguage != null && videoLanguage.isNotEmpty) {
        videoTrackData.addAll(Ebml.writeString(0x22B59C, _toIso639_2(videoLanguage)));
      }

      if (fps > 0) {
        int defaultDurationNs = (1000000000 / fps).round();
        videoTrackData.addAll(Ebml.writeUint(0x23E383, defaultDurationNs));
      }

      videoTrackData.addAll(Ebml.writeData(0x63A2, avcc));
      videoTrackData.addAll(Ebml.writeData(0xE0, [...Ebml.writeUint(0xB0, width), ...Ebml.writeUint(0xBA, height)]));

      tracksData.addAll(Ebml.writeData(0xAE, videoTrackData));
    }

    for (final track in audioTracks) {
      tracksData.addAll(_buildAudioTrackEntry(track));
    }

    for (final track in subtitleTracks) {
      tracksData.addAll(_buildSubtitleTrackEntry(track));
    }

    _file!.writeFromSync(Ebml.writeData(0x1654AE6B, tracksData));
  }

  /// Opens the MKV container. Supports both traditional single-audio usage
  /// and custom [audioTracks] and [subtitleTracks] for separate audio streams.
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
    List<MkvAudioTrack>? audioTracks,
    List<MkvSubtitleTrack>? subtitleTracks,
  }) async {
    final effectiveAudioTracks = <MkvAudioTrack>[];
    if (audioTracks != null && audioTracks.isNotEmpty) {
      effectiveAudioTracks.addAll(audioTracks);
    } else if (audioConfig != null) {
      effectiveAudioTracks.add(
        MkvAudioTrack(
          trackNumber: 2,
          codecPrivate: audioConfig,
          sampleRate: audioSampleRate,
          channels: audioChannels,
          isDefault: true,
        ),
      );
    }

    final effectiveSubtitleTracks = <MkvSubtitleTrack>[];
    if (subtitleTracks != null && subtitleTracks.isNotEmpty) {
      effectiveSubtitleTracks.addAll(subtitleTracks);
    } else if (addSubtitleTrack) {
      final nextTrackNumber = effectiveAudioTracks.isEmpty
          ? 2
          : effectiveAudioTracks.map((t) => t.trackNumber).reduce(math.max) + 1;
      effectiveSubtitleTracks.add(
        MkvSubtitleTrack(
          trackNumber: nextTrackNumber,
          codecId: subtitleCodecId,
          isDefault: true,
        ),
      );
    }

    await openWithTracks(
      avcc: avcc,
      audioTracks: effectiveAudioTracks,
      subtitleTracks: effectiveSubtitleTracks,
      width: width,
      height: height,
      fps: fps,
    );
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

    if (trackNumber == _videoTrackNumber && isKeyframe) {
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

  /// Convenience method to write a block when the timestamp is already in milliseconds.
  void writeBlockMs(int trackNumber, List<int> data, int timecodeMs, bool isKeyframe) {
    writeBlock(trackNumber, data, timecodeMs * 90, isKeyframe);
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
            ...Ebml.writeUint(0xF7, _videoTrackNumber),
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
