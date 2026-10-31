import 'package:animestream/core/commons/hlsParser/audioStream.dart';
import 'package:animestream/core/commons/hlsParser/qualityStream.dart';

class HlsMasterPlaylist {
  final List<QualityStream> qualityStreams;
  final List<AudioStream> audioStreams;

  const HlsMasterPlaylist({required this.audioStreams, required this.qualityStreams});

  factory HlsMasterPlaylist.defaultStream(String streamUrl) {
    return HlsMasterPlaylist(
      audioStreams: [],
      qualityStreams: [QualityStream(quality: "default", url: streamUrl, resolution: "??")],
    );
  }
}