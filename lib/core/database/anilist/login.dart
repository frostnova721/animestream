import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/data/secureStorage.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/core/database/database.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class AniListLogin extends DatabaseLogin {
  String url = "https://anilist.co/api/v2/oauth/authorize?client_id=15179&response_type=token";

  String _extractToken(String url) {
    final RegExp regExp = RegExp(r'access_token=(.*?)&token_type=');
    final match = regExp.firstMatch(url);
    if (match != null) {
      final token = match.group(1);
      if (token != null) return token;
      throw new Exception("ERR_COULDNT_EXTRACT_TOKEN");
    } else {
      throw new Exception("ERR_COULDNT_EXTRACT_TOKEN");
    }
  }

  /**Will only return bool (i hope) */
  @override
  Future<bool> initiateLogin() async {
    final res = await FlutterWebAuth2.authenticate(url: url, callbackUrlScheme: "auth.animestream");
    if (!res.contains("access_token")) {
      print("ERR_RECIEVED_AUTH_CODE_NULL");
      return false;
    } else {
      await storeSecureVal(SecureStorageKey.anilistToken, _extractToken(res));
      return true;
    }
    // final nav = Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => WebView(url: url),
    //   ),
    // );
    // return nav;
  }

  Future<void> removeToken() async {
    // await storeVal('token', null);
    await storeSecureVal(SecureStorageKey.anilistToken, null);
  }

  Future<UserModal> getUserProfile() async {
    final query = '''{
  Viewer {
    id
    avatar {
      medium
      large
    }
    name
    bannerImage
  }
}''';

    // final String? token = await getVal("token");
    final String? token = await getSecureVal(SecureStorageKey.anilistToken);
    if (token == null) throw new Exception("ERR_COULDNT_GET_TOKEN");

    final res = await Anilist().fetchQuery(query, null, token: token);

    final data = res['Viewer'];
    return UserModal(
        id: data['id'],
        avatar: data['avatar']['large'] ?? data['avatar']['medium'],
        name: data['name'],
        banner: data['bannerImage']);
  }

  Future<bool> isAnilistLoggedIn() async {
    String? token;
    try {
      token = await getSecureVal(SecureStorageKey.anilistToken);
    } catch (err) {
      //why not
      token = await getSecureVal(SecureStorageKey.anilistToken);
    }
    if (token != null) return true;
    return false;
  }
}
