import 'dart:async';
import 'dart:convert';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart';

class SimklLogin {
  static const callbackScheme = "auth.animestream://";

  static Future<void> initiateLogin() async {
    final clientId = simklClientId;
    final clientSecret = dotenv.get("SIMKL_CLIENT_SECRET");
    if (clientSecret.isEmpty || clientId.isEmpty) {
      throw Exception("Error: SIMKL CLIENT ID OR SECRET NOT PROVIDED!");
    }
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

  static Future<PCKECodeResult> getPckeCode() async {
    final url = "https://api.simkl.com/oauth/pin?client_id=$simklClientId";
    final res = await get(Uri.parse(url));
    if (res.statusCode != 200) throw new Exception("Couldnt Get Code for Login");
    final jsoned = jsonDecode(res.body);
    final expSeconds = Duration(seconds: int.parse(jsoned['expires_in']));
    final currentUtcTime = DateTime.now().toUtc();
    final codeData = PCKECodeResult(
      userCode: jsoned['user_code'],
      verificationUrl: jsoned['verification_url'],
      deviceCode: jsoned['device_code'],
      expiry: currentUtcTime.add(expSeconds),
      interval: jsoned['interval'],
    );
    return codeData;
  }

  //function to call for polling
  static Future<bool> verifyPckeCode(PCKECodeResult codeRes) async {
    final url = "https://api.simkl.com/oauth/pin/${codeRes.userCode}?client_id=$simklClientId";
    final Completer<bool> completer = Completer<bool>();
    int failCount = 0;
    Timer.periodic(Duration(seconds: codeRes.interval), (timer) async {
      //kill after 5 failed request attempts
      if (failCount > 5) {
        timer.cancel();
        completer.complete(false);
      } else if (DateTime.now().isAfter(codeRes.expiry)) {
        timer.cancel();
        completer.completeError(Exception("CODE_EXPIRED"));
      } else {
        try {
          final res = await get(Uri.parse(url));
          final jsoned = jsonDecode(res.body);

          //stop the timer and save the token
          if (jsoned['result'] == "OK") {
            final storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
            await storage.write(key: "simkl_token", value: jsoned['access_token']);
            print("[SIMKL-LOGIN]: Login success, Access token saved!");
            timer.cancel();
            completer.complete(true);
          }
        } catch (err) {
          print(err);
          failCount++;
        }
      }
    });
    return await completer.future;
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

class PCKECodeResult {
  final String userCode;
  final String verificationUrl;
  final String deviceCode;
  final DateTime expiry;
  final int interval;

  PCKECodeResult({
    required this.userCode,
    required this.verificationUrl,
    required this.deviceCode,
    required this.expiry,
    required this.interval,
  });
}
