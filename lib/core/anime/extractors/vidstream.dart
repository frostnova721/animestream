import "dart:convert";

import "package:animestream/core/anime/extractors/type.dart";
import "package:animestream/core/anime/providers/types.dart";
import "package:http/http.dart";
import "package:html/parser.dart" as html;
import "package:encrypt/encrypt.dart";

class GogoVidstream extends AnimeExtractor {
  final keys = {
    'key': Key.fromUtf8('37911490979715163134003223491201'),
    'secondKey': Key.fromUtf8('54674138327930866480207815084989'),
    'iv': IV.fromUtf8('3134003223491201'),
  };

  final baseUrl = "https://gogoanime3.net";

  Future<List<VideoStream>> extract(String streamLink) async {
    if(streamLink.isEmpty) {
      throw new Exception("ERR_EMPTY_STREAM_LINK");
    }
    final epLink = Uri.parse(streamLink);
    final id = epLink.queryParameters['id'] ?? '';
    final encrypedKey = await getEncryptedKey(id);
    final decrypted = await decrypt(epLink);
    final params = "id=$encrypedKey&alias=$id&$decrypted";

    final res = (await get(
        Uri.parse(
            "${epLink.scheme}://${epLink.host}/encrypt-ajax.php?${params}"),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
        }));
    final encryptedData = json.decode(res.body)['data'];

    final Encrypter encrypter =
        Encrypter(AES(keys['secondKey'] as Key, mode: AESMode.cbc));
    final dec = encrypter.decrypt(Encrypted.fromBase64(encryptedData), iv: keys['iv'] as IV);
    
    final parsed = json.decode(dec);

    List<VideoStream> qualityList = [];

    if(parsed['source'] == null && parsed['source_bk'] == null) throw new Exception("No stream found");

    for(final src in parsed['source']) {
      qualityList.add(VideoStream(
        quality: "multi-quality",
        link: src['file'],
        isM3u8: src['file'].endsWith(".m3u8"),
        server: "vidstreaming",
        backup: false
      ));
    }

    return qualityList;
  }

  Future<String> fetch(String url) async {
    final res = await get(Uri.parse(url));
    return res.body;
  }

  getEncryptedKey(String id) async {
    try {
      final encrypter = Encrypter(AES(keys['key'] as Key, mode: AESMode.cbc));
      final encrypedKey = encrypter.encrypt(id, iv: keys['iv'] as IV);
      return encrypedKey.base64;
    } catch (err) {
      print(err);
    }
  }

  decrypt(Uri streamLink) async {
    final res = await fetch(streamLink.toString());
    final doc = html.parse(res);
    final String val = doc
            .querySelector('script[data-name="episode"]')
            ?.attributes['data-value'] ??
        '';
    if (val.length == 0) return null;
    final Encrypter encrypter =
        Encrypter(AES(keys['key'] as Key, mode: AESMode.cbc, padding: null));
    final decrypted =
        encrypter.decrypt(Encrypted.fromBase64(val), iv: keys['iv'] as IV);
    return decrypted;
  }

  Future getIframeLink(String epLink) async {
    final res = await fetch(epLink);
    final doc = html.parse(res);
    final String link = doc.querySelector("iframe")?.attributes['src'] ?? '';
    if (link.length == 0) return null;
    return link;
  }
}

