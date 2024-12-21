import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:animestream/core/database/mal/types.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart';

class MALLogin extends DatabaseLogin {

  final _clientId = "165c40bb79c803049c4badcaa90cfd74";

  @override
  Future<bool> initiateLogin() async {
    final verifier = generateCodeVerifier();
    final challenge = generateCodeChallenge(verifier);

    await storeSecureVal(SecureStorageKey.malChallengeVerifier, verifier);

    final redirect = "auth.animestream://callback";
    final state = generateState();

    final loginUrl =
     "https://myanimelist.net/v1/oauth2/authorize?response_type=code&client_id=$_clientId&code_challenge=$challenge&redirect_uri=$redirect&state=$state";

    final req = await FlutterWebAuth2.authenticate(
        url: loginUrl, callbackUrlScheme: redirect.split(":")[0]);

    final queries = Uri.parse(req).queryParameters;

    final returnedState = queries['state'];
    final code = queries['code'];
    if (returnedState != state) {
      throw Exception("THE REQUEST IS POSSIBLY TAMPERED, REJECTING TOKEN...");
    }

    if (code == null) {
      throw Exception("RECIEVED MAL RESPONSE CODE AS NULL");
    }

    final acurl = "https://myanimelist.net/v1/oauth2/token";

    final reqBody = {
      'client_id': _clientId,
      'grant_type': "authorization_code",
      'code': code,
      'code_verifier': challenge,
      'redirect_uri': redirect,
    };

    final res = await post(Uri.parse(acurl), body: reqBody, headers: {'Content-Type': 'application/x-www-form-urlencoded'});

    // if(res != 302) return false;

    final classed = MALAuthResponse.fromMap(jsonDecode(res.body));

    await storeSecureVal(SecureStorageKey.malAuthResponse, classed.toJson());
    await storeSecureVal(SecureStorageKey.malToken, classed.accessToken);

    print("[MAL-LOGIN]: Login success, Access token has been saved!");
    return true;
  }

  @override
  Future<void> removeToken() async {
    await storeSecureVal(SecureStorageKey.malToken, null);
  }

  String generateState() {
    final length = 16;
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final state = List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();

    return state;
  }

  String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final shaDigest = sha256.convert(bytes);
    final challege = base64UrlEncode(Uint8List.fromList(shaDigest.bytes)).replaceAll("=", "");

    

    return challege;
  }

  String generateCodeVerifier() {
    final int byteLength = 81;
    final random = Random.secure();
    final byteList = List.generate(byteLength, (ind) => random.nextInt(256));
    final verifier = base64UrlEncode(byteList).replaceAll("=", "");

    return verifier.substring(0, byteLength); //just in case to match the length
  }
  
  @override
  Future<void>? refreshToken() async {
    final authResp = await getSecureVal(SecureStorageKey.malToken);
    if(authResp == null) throw Exception("FOUND AUTH RESPONSE AS NULL. TRY LOGGING IN TO MAL AGAIN");
    final classed = MALAuthResponse.fromMap(jsonDecode(authResp));
    final body = jsonEncode({
      'client_id': _clientId,
      "refresh_token": classed.refreshToken,
      "grant_type": "refresh_token",
    });
    final res = await post(Uri.parse("https://myanimelist.net/v1/oauth2/token"), body: body);
    if(res != 200) throw Exception("COULDNT REFRESH THE TOKEN");

    final classedRes = MALAuthResponse.fromMap(jsonDecode(res.body));

    await storeSecureVal(SecureStorageKey.malAuthResponse, classedRes.toJson());
    await storeSecureVal(SecureStorageKey.malToken, classedRes.accessToken);

    print("[MAL-LOGIN]: Token refreshed, Access token has been saved!");
  }

  Future<UserModal> getUserProfile() async {
    final url = "https://api.myanimelist.net/v2/users/@me";

    final res = await get(Uri.parse(url));
    print(res.body);
    return UserModal(avatar: "", banner: "", id: 0, name: "");
  }
}
