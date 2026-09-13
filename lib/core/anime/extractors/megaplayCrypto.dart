import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class MegaplayCrypto {
  static const _aesKey = 'i?LMTAx0Q6,:}50U';
  static const _iv = "W0;27ToaUpl_P%'c";
  static const _tokenKey = 'MpCdnT0k3n!9f2K#xQ7vL5mR8wN1pY4s';

  static String? sourceFile(Map<String, dynamic> response) {
    final encrypted = response['enc'];
    if (encrypted is String && encrypted.isNotEmpty) {
      final key = Uint8List(32)..setAll(0, utf8.encode(_aesKey));
      final cipher =
          enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
      final plaintext = cipher.decrypt(
        enc.Encrypted(base64Url.decode(base64Url.normalize(encrypted))),
        iv: enc.IV.fromUtf8(_iv),
      );
      return (jsonDecode(plaintext) as Map<String, dynamic>)['file'] as String?;
    }
    final sources = response['sources'];
    if (sources is Map) return sources['file'] as String?;
    if (sources is List && sources.isNotEmpty && sources.first is Map) {
      return sources.first['file'] as String?;
    }
    return null;
  }

  // Matches e1-player.min.js: HMAC the raw payload, then encode both parts.
  static String signUrl(String fileUrl, {DateTime? now}) {
    final uri = Uri.parse(fileUrl);
    final ids = RegExp(r'/([a-f0-9]{32})/([a-f0-9]{32})/', caseSensitive: false)
        .firstMatch(uri.path);
    if (ids == null) return fileUrl;
    final expires = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000 + 90;
    final payload = utf8
        .encode('$expires|${ids[1]!.toLowerCase()}/${ids[2]!.toLowerCase()}');
    final signature =
        Hmac(sha256, utf8.encode(_tokenKey)).convert(payload).bytes;
    String encode(List<int> bytes) =>
        base64Url.encode(bytes).replaceAll('=', '');
    return uri.replace(queryParameters: {
      ...uri.queryParametersAll,
      'token': ['${encode(payload)}.${encode(signature)}'],
    }).toString();
  }
}
