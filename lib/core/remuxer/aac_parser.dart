import 'dart:typed_data';

class AacParser {
  int? samplingFrequencyIndex;
  int? channelConfiguration;
  int? audioObjectType;

  final BytesBuilder _buffer = BytesBuilder();
  int? _nextPts;
  int? _nextDts;

  List<ParsedAacFrame> processPes(List<int>? payload, int? pts, int? dts) {
    if (payload != null) {
      _buffer.add(payload);
    }
    
    if (pts != null) {
      _nextPts = pts;
      _nextDts = dts ?? pts;
    }

    final frames = <ParsedAacFrame>[];
    final data = _buffer.toBytes();
    int offset = 0;

    while (offset < data.length - 7) {
      if (data[offset] == 0xFF && (data[offset + 1] & 0xF0) == 0xF0) {
        final protectionAbsent = (data[offset + 1] & 0x01) == 1;
        final profile = (data[offset + 2] >> 6) & 0x03;
        final sfIndex = (data[offset + 2] >> 2) & 0x0F;
        final channelConfig = ((data[offset + 2] & 0x01) << 2) | ((data[offset + 3] >> 6) & 0x03);
        
        final frameLength = ((data[offset + 3] & 0x03) << 11) |
            (data[offset + 4] << 3) |
            ((data[offset + 5] >> 5) & 0x07);

        if (samplingFrequencyIndex == null) {
          audioObjectType = profile + 1;
          samplingFrequencyIndex = sfIndex;
          channelConfiguration = channelConfig;
        }

        int headerLength = protectionAbsent ? 7 : 9;
        
        if (offset + frameLength <= data.length) {
          final rawFrame = data.sublist(offset + headerLength, offset + frameLength);
          
          _parsePceIfNeeded(rawFrame);

          if (_nextPts != null && _nextDts != null) {
            frames.add(ParsedAacFrame(rawFrame, _nextPts!, _nextDts!));
            double sr = getCoreSamplingRate();
            if (sr > 0) {
              int offsetPts = (1024 * 90000 ~/ sr);
              _nextPts = _nextPts! + offsetPts;
              _nextDts = _nextDts! + offsetPts;
            }
          }
          
          offset += frameLength;
        } else {
          break;
        }
      } else {
        offset++;
      }
    }

    if (offset > 0) {
      final remaining = data.sublist(offset);
      _buffer.clear();
      _buffer.add(remaining);
    }

    return frames;
  }

  bool _pceParsed = false;

  void _parsePceIfNeeded(List<int> rawFrame) {
    if (_pceParsed || rawFrame.isEmpty) return;
    _pceParsed = true;

    if (channelConfiguration != 0) return;

    final br = _BitReader(rawFrame);
    int id = br.readBits(3);
    if (id == 5) { // PCE
      br.readBits(4); 
      br.readBits(2); 
      int sfIndex = br.readBits(4);
      samplingFrequencyIndex = sfIndex; 
      channelConfiguration = 2; 
    } else {
      channelConfiguration = 2; 
    }
  }

  List<int>? buildAudioSpecificConfig() {
    if (audioObjectType == null || samplingFrequencyIndex == null || channelConfiguration == null) {
      return null;
    }

    // Force core AOT to 2 (AAC-LC) if it was incorrectly parsed as 1 (AAC-Main)
    // HE-AAC relies on LC as its core, and ADTS headers for HE-AAC streams
    // occasionally contain profile 0 (AOT 1) incorrectly.
    int coreAot = audioObjectType! == 1 ? 2 : audioObjectType!; 
    int coreSrIndex = samplingFrequencyIndex!;
    int coreChannels = channelConfiguration! == 0 ? 2 : channelConfiguration!; // Fallback to stereo if PCE (0)

    // Stronger Heuristic for ADTS with PCE (channelConfiguration == 0):
    // Encoders often incorrectly write the EXTENSION sample rate (44.1k/48k) in the ADTS header instead of the core.
    if (channelConfiguration! == 0) {
      if (coreSrIndex == 4) coreSrIndex = 7; // 44100 -> 22050 (HE-AAC core)
      else if (coreSrIndex == 3) coreSrIndex = 6; // 48000 -> 24000 (HE-AAC core)
    }

    // Use implicit signaling for HE-AAC. We simply output the core AAC-LC AudioSpecificConfig.
    // Modern decoders will read this basic config, parse the bitstream, and implicitly
    // discover SBR and PS data to upscale the audio appropriately.
    final bw = _BitWriter();
    bw.writeBits(coreAot, 5);
    bw.writeBits(coreSrIndex, 4);
    bw.writeBits(coreChannels, 4);
    bw.flush();
    return bw.bytes;
  }

  int getOutputChannels() {
    int coreChannels = channelConfiguration ?? 2;
    if (coreChannels == 0) coreChannels = 2; // Default to stereo if PCE (0)
    int index = samplingFrequencyIndex ?? 4;
    bool isHeAac = index >= 6 && index <= 8;
    bool isPs = isHeAac && coreChannels == 1;
    return isPs ? 2 : coreChannels;
  }

  double getCoreSamplingRate() {
    int index = samplingFrequencyIndex ?? 4;
    if (channelConfiguration == 0) {
      if (index == 4) index = 7;
      else if (index == 3) index = 6;
    }
    return _sampleRateForIndex(index);
  }

  double getSamplingRate() {
    int index = samplingFrequencyIndex ?? 4;
    if (channelConfiguration == 0) {
      if (index == 4) index = 7;
      else if (index == 3) index = 6;
    }
    if (index >= 6 && index <= 8) {
      index = index - 3; // SBR doubles the sample rate
    }
    return _sampleRateForIndex(index);
  }

  double _sampleRateForIndex(int index) {
    switch (index) {
      case 0: return 96000;
      case 1: return 88200;
      case 2: return 64000;
      case 3: return 48000;
      case 4: return 44100;
      case 5: return 32000;
      case 6: return 24000;
      case 7: return 22050;
      case 8: return 16000;
      case 9: return 12000;
      case 10: return 11025;
      case 11: return 8000;
      case 12: return 7350;
      default: return 44100;
    }
  }
}

class ParsedAacFrame {
  final List<int> data;
  final int pts;
  final int dts;

  ParsedAacFrame(this.data, this.pts, this.dts);
}

class _BitReader {
  final List<int> data;
  int _byteOffset = 0;
  int _bitOffset = 0;

  _BitReader(this.data);

  int readBits(int numBits) {
    int result = 0;
    for (int i = 0; i < numBits; i++) {
      if (_byteOffset >= data.length) return result;
      int bit = (data[_byteOffset] >> (7 - _bitOffset)) & 1;
      result = (result << 1) | bit;
      _bitOffset++;
      if (_bitOffset == 8) {
        _bitOffset = 0;
        _byteOffset++;
      }
    }
    return result;
  }
}

class _BitWriter {
  int _data = 0;
  int _bits = 0;
  final List<int> bytes = [];

  void writeBits(int value, int numBits) {
    for (int i = numBits - 1; i >= 0; i--) {
      int bit = (value >> i) & 1;
      _data = (_data << 1) | bit;
      _bits++;
      if (_bits == 8) {
        bytes.add(_data);
        _data = 0;
        _bits = 0;
      }
    }
  }

  void flush() {
    if (_bits > 0) {
      _data <<= (8 - _bits);
      bytes.add(_data);
      _bits = 0;
    }
  }
}
