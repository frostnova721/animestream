import 'dart:convert';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart';

class SimklLogin {
  static Future<void> initiateLogin() async {
    final clientId = simklClientId;
    final clientSecret = dotenv.get("SIMKL_CLIENT_SECRET");
    if (clientSecret.isEmpty || clientId.isEmpty) {
      throw Exception("Error: SIMKL CLIENT ID OR SECRET NOT PROVIDED!");
    }
    final callbackScheme = "auth.animestream://";
    final authUrl = Uri.https("simkl.com", "/oauth/authorize", {
      'client_id': clientId,
      'response_type': "code",
      'redirect_uri': callbackScheme,
    });
    final res =
        await FlutterWebAuth2.authenticate(url: authUrl.toString(), callbackUrlScheme: callbackScheme.split(":")[0]);
    final code = Uri.parse(res).queryParameters['code'];
    if (code == null) {
      throw Exception("ERR_RECIEVED_AUTH_CODE_NULL");
    }
    final reqBody = jsonEncode({
      'code': code,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': callbackScheme,
      'grant_type': "authorization_code"
    });
    final atres = await post(Uri.parse("https://api.simkl.com/oauth/token"),
        body: reqBody, headers: {'Content-Type': "application/json"});
    final json = jsonDecode(atres.body);
    final at = json['access_token'];

    if (at.isEmpty) throw Exception("ACCESS TOKEN IS NULL!");

    final storage = new FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    storage.write(key: "simkl_token", value: at);

    print("[SIMKL-LOGIN]: Login success, Access token saved!");
  }

  static Future<void> removeToken() async {
    final storage = new FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    storage.delete(key: "simkl_token");
  }

  static Future<bool> isLoggedIn() async {
    final storage = new FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    final token = await storage.read(key: "simkl_token");
    if (token == null || token.isEmpty) {
      return false;
    }
    return true;
  }
}
