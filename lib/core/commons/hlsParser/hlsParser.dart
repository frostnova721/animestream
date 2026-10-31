// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:animestream/core/commons/hlsParser/audioStream.dart';
import 'package:animestream/core/commons/hlsParser/hlsMasterPlaylist.dart';
import 'package:animestream/core/commons/hlsParser/hlsSegment.dart';
import 'package:animestream/core/commons/hlsParser/qualityStream.dart';
import 'package:animestream/core/network/network.dart';

class HlsParser {
  static Future<bool> isM3u8Playlist(String url, {Map<String, String>? customHeader}) async {
    if (url.toLowerCase().split('?').firstOrNull?.endsWith(".m3u8") ?? false) return true;

    // This is very weak, to video files. If they dont support the range header!
    try {
      final res = await get(
        Uri.parse(url),
        headers: {
          ...?customHeader,
          "Range": "bytes=0-8192", // read 8kb
        },
        cacheDuration: const Duration(hours: 1),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        print(res.statusCode);
        return false;
      }

      final lines = res.body.trim().split("\n").where((e) => e.isNotEmpty);
      return lines.first.trim() == "#EXTM3U";
    } catch (e) {
      return false;
    }
  }

  static Map<String, String> _parseAttributes(String line) {
    final attrs = <String, String>{};
    for (final m in RegExp(r'([A-Z0-9\-]+)=(".*?"|[^,]*)').allMatches(line)) {
      attrs[m.group(1)!] = m.group(2)!.replaceAll('"', '');
    }
    return attrs;
  }

  static Future<HlsMasterPlaylist> parseMasterPlaylist(String streamUrl, {Map<String, String>? customHeader}) async {
    List<AudioStream> audioStreams = [];
    List<QualityStream> qualityStreams = [];

    if (!await isM3u8Playlist(streamUrl, customHeader: customHeader)) {
      throw Exception("Not a valid m3u8 playlist");
    }

    final baseUri = Uri.parse(streamUrl);

    final content = (await get(
      Uri.parse(streamUrl),
      headers: customHeader,
      cacheDuration: const Duration(hours: 1),
    )).body;
    List<String> lines = content.trim().split("\n").where((e) => e.isNotEmpty).toList();
    // lines = lines.where((it) => !it.startsWith("EXT-X-MEDIA")).toList().first.split("\n");

    // final regex = RegExp(r'RESOLUTION=(\d+x\d+)');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith("#")) {
        // we dont need these info yet
        // if (line.startsWith('#EXTM3U') || line.startsWith('#EXT-X-I-FRAME') || line.startsWith("#EXT-X-MEDIA") || line.startsWith("#EXT-X-VERSION"))

        if (line.startsWith("#EXT-X-MEDIA:TYPE=AUDIO")) {
          final asb = AudioStreamBuilder();
          final attrs = _parseAttributes(line);

          // in hopes that the playlist will contain everything we neeed!
          if (attrs.containsKey("GROUP-ID")) asb.addGroupId(attrs["GROUP-ID"]!);

          if (attrs.containsKey("LANGUAGE")) asb.addLanguage(attrs["LANGUAGE"]!);

          if (attrs.containsKey("CHANNELS")) asb.addChannels(attrs["CHANNELS"]!);

          if (attrs.containsKey("NAME")) asb.addName(attrs["NAME"]!);
          if (attrs.containsKey("URI")) {
            final linkPart = attrs["URI"]!;
            asb.addUrl(linkPart.startsWith('http') ? linkPart : "${_makeBaseLink(streamUrl)}/$linkPart");
          }
          // }
          // }

          audioStreams.add(asb.build());
        }

        // ignore all other stuff
        if (!line.startsWith("#EXT-X-STREAM-INF")) continue;

        final qsb = QualityStreamBuilder();
        final streamAttrs = _parseAttributes(line.substring(line.indexOf(':') + 1));
        if (streamAttrs.containsKey("BANDWIDTH")) qsb.addBandwidth(int.parse(streamAttrs["BANDWIDTH"]!));
        if (streamAttrs.containsKey("RESOLUTION")) qsb.addResolution(streamAttrs["RESOLUTION"]!);
        if (streamAttrs.containsKey("AUDIO")) qsb.addAudioGroup(streamAttrs["AUDIO"]!);

        final urlLine = lines[i + 1];
        final linkPart = urlLine.trim().replaceAll('"', '');
        if (linkPart.length > 1) qsb.addUrl(baseUri.resolve(linkPart).toString());
        // qsb.addUrl(linkPart.startsWith('http') ? linkPart : "${_makeBaseLink(streamUrl)}/$linkPart");

        final quality = qsb.resolution != null ? qsb.resolution!.split('x')[1] + "p" : "default";
        qsb.addQuality(quality);

        qualityStreams.add(qsb.build());

        i++; // skip the next iteration since it should be the link to video.
      }
    }
    print(audioStreams);
    print(qualityStreams);

    // It should be a static stream
    if (qualityStreams.isEmpty) {
      print("The stream is of static quality.");
      return HlsMasterPlaylist.defaultStream(streamUrl);
    }

    final grouped = HlsMasterPlaylist(audioStreams: audioStreams, qualityStreams: qualityStreams);

    return grouped;
  }

  static Future<List<HlsSegment>> parseSegments(String url, {Map<String, String> customHeaders = const {}}) async {
    final List<HlsSegment> segments = [];
    final baseUri = Uri.parse(url);
    final res = await get(baseUri, headers: customHeaders);
    final lines = res.body.split('\n');

    int sequenceNumber = 0;
    double duration = 0.0;
    HlsEncryptionKey? currentKey;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('EXT-X-MEDIA-SEQUENCE:')) {
        sequenceNumber = int.tryParse(line.substring(22)) ?? 0;
      } else if (line.startsWith('EXT-X-KEY:')) {
        final attrs = _parseAttributes(line.substring(11));
        final method = attrs['METHOD'] ?? "NONE";

        if (method == "NONE") {
          currentKey = null;
        } else {
          final uri = attrs['URI'];
          final iv = attrs['IV'];
          if (uri != null) {
            currentKey = HlsEncryptionKey(method: method, uri: baseUri.resolve(uri).toString(), iv: iv);
          }
        }
      } else if (line.startsWith('EXTINF:')) {
        duration = double.tryParse(line.substring(8).split(',')[0]) ?? 0.0;
      } else if (!line.startsWith('#')) {
        final segmentUrl = baseUri.resolve(line).toString();
        segments.add(
          HlsSegment(url: segmentUrl, duration: duration, sequenceNumber: sequenceNumber++, encryptionKey: currentKey),
        );
      }
    }
    return segments;
  }

  static String _makeBaseLink(String uri) {
    final split = uri.split('/');
    split.removeLast();
    return split.join('/');
  }
}
