// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:http/http.dart';

class ParsedHlsMaster {
  final List<QualityStream> qualityStreams;
  final List<AudioStream> audioStreams;

  const ParsedHlsMaster({required this.audioStreams, required this.qualityStreams});
}

class AudioStreamBuilder {
  String? language;
  String? url;
  String? name;
  String? channels;
  String? groupId;

  AudioStream build() {
    if (language == null || url == null || name == null || channels == null || groupId == null) {
      throw Exception("One of the required arguments for the AudioStream was received as null");
    }
    return AudioStream(groupId: groupId!, name: name!, url: url!, language: language!, channels: channels!);
  }

  void addGroupId(String groupId) => this.groupId = groupId;

  void addChannels(String channels) => this.channels = channels;

  void addName(String name) => this.name = name;

  void addUrl(String url) => this.url = url;

  void addLanguage(String language) => this.language = language;
}

class AudioStream {
  final String language;
  final String url;
  final String name;
  final String channels;
  final String groupId;

  const AudioStream({
    required this.groupId,
    required this.name,
    required this.url,
    required this.language,
    required this.channels,
  });

  factory AudioStream.placeholder() {
    return AudioStream(groupId: "who cares", name: "mic testing!", url: "placeholder", language: "english", channels: "stereo");
  }

  @override
  String toString() {
    return 'AudioStream(language: $language, url: $url, name: $name, channels: $channels, groupId: $groupId)';
  }
}

class QualityStream {
  String quality;
  String url;
  String resolution;
  String? audioGroup;
  int? bandwidth;

  QualityStream({
    required this.quality,
    required this.url,
    required this.resolution,
    this.audioGroup,
    this.bandwidth,
  });

  factory QualityStream.paceholder() {
    return QualityStream(quality: "unset", url: "unknown", resolution: "0x0");
  }

  Map<String, dynamic> toMap() {
    return {
      'quality': quality,
      'url': url,
      'resolution': resolution,
      'audioGroup': audioGroup,
      'bandwidth': bandwidth,
    };
  }

  @override
  String toString() {
    return 'QualityStream(quality: $quality, url: $url, resolution: $resolution, audioGroup: $audioGroup, bandwidth: $bandwidth)';
  }
}

class QualityStreamBuilder {
  String? quality;
  String? url;
  String? resolution;
  String? audioGroup;
  int? bandwidth;

  void addResolution(String resolution) => this.resolution = resolution;
  void addUrl(String url) => this.url = url;
  void addQuality(String quality) => this.quality = quality;
  void addBandwidth(int bandwidth) => this.bandwidth = bandwidth;
  void addAudioGroup(String audioGroup) => this.audioGroup = audioGroup;

  QualityStream build() {
    if(quality == null || url == null || resolution == null) {
      print("res: $resolution, url: $url, quality: $quality");
      throw Exception("One of the required arguments for the QualityStream was received as null");
    }
    return QualityStream(quality: quality!, url: url!, resolution: resolution!, audioGroup: audioGroup, bandwidth: bandwidth);
  }
}

Future<ParsedHlsMaster> parseMasterPlaylist(String streamUrl, {Map<String, String>? customHeader = null}) async {
  try {
    final content = (await get(Uri.parse(streamUrl), headers: customHeader)).body;

    List<AudioStream> audioStreams = [];
    List<QualityStream> qualityStreams = [];

    List<String> lines = content.split("\n");
    // lines = lines.where((it) => !it.startsWith("EXT-X-MEDIA")).toList().first.split("\n");

    // final regex = RegExp(r'RESOLUTION=(\d+x\d+)');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith("#")) {
        // we dont need these info yet
        // if (line.startsWith('#EXTM3U') || line.startsWith('#EXT-X-I-FRAME') || line.startsWith("#EXT-X-MEDIA") || line.startsWith("#EXT-X-VERSION"))
        if (line.startsWith("#EXT-X-MEDIA:TYPE=AUDIO")) {
          final asb = AudioStreamBuilder();
          final items = line.split(",").sublist(1); // this will remove the "#EXT-X-MEDIA:TYPE=AUDIO" part
          for (final it in items) {
            final kvPair = it.split("=");
            if (kvPair.length < 2) {
              print("Possible malformed playlist. Skipping the element '$kvPair'.");
              continue;
            }

            // in hopes that the playlist will contain everything we neeed!
            switch (kvPair[0]) {
              case "GROUP-ID":
                asb.addGroupId(kvPair[1].replaceAll('"', ''));
              case "LANGUAGE":
                asb.addLanguage(kvPair[1].replaceAll('"', ''));
              case "CHANNELS":
                asb.addChannels(kvPair[1].replaceAll('"', ''));
              case "NAME":
                asb.addName(kvPair[1].replaceAll('"', ''));
              case "URI":
                {
                  final linkPart = kvPair[1].replaceAll('"', '');
                  asb.addUrl(linkPart.startsWith('http') ? linkPart : "${_makeBaseLink(streamUrl)}/$linkPart");
                }
            }
          }

          audioStreams.add(asb.build());
        }

        // ignore all other stuff
        if (!line.startsWith("#EXT-X-STREAM-INF")) continue;

        final qsb = QualityStreamBuilder();
        final items = line.split(":")[1].split(",");
        for(final it in items) {
          final kvPair = it.split("=");
          switch(kvPair[0]) {
            case "BANDWIDTH": qsb.addBandwidth(int.parse(kvPair[1]));
            case "RESOLUTION": qsb.addResolution(kvPair[1]);
            case "AUDIO": qsb.addAudioGroup(kvPair[1]);
          }
        }

        final urlLine = lines[i+1];
        final linkPart = urlLine.trim().replaceAll('"', '');
        if (linkPart.length > 1)
          qsb.addUrl(linkPart.startsWith('http') ? linkPart : "${_makeBaseLink(streamUrl)}/$linkPart");

        final quality = qsb.resolution != null ? qsb.resolution!.split('x')[1] + "p" : "default";
        qsb.addQuality(quality);

        qualityStreams.add(qsb.build());
        // final match = regex.allMatches(line).first;
        // resolutions.add(match.group(0)?.replaceAll("RESOLUTION=", '') ?? 'null');

        i++; // skip the next iteration since it should be the link to video.
      }
    }
    // print(audioStreams);
    // print(qualityStreams);

    // throw an exception to return the default item
    if (qualityStreams.isEmpty) throw Exception("The stream is of static quality.");

    final grouped = ParsedHlsMaster(audioStreams: audioStreams, qualityStreams: qualityStreams);

    return grouped;
  } catch (err) {
    print(err);
    return ParsedHlsMaster(audioStreams: [], qualityStreams: [
      QualityStream(quality: "default", url: streamUrl, resolution: "??")
    ]);
  }
}

String _makeBaseLink(String uri) {
  final split = uri.split('/');
  split.removeLast();
  return split.join('/');
}
