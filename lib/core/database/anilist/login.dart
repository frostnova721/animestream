import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/webView.dart';
import 'package:flutter/material.dart';

class AniListLogin {
  String url =
      "https://anilist.co/api/v2/oauth/authorize?client_id=15179&response_type=token";

  /**Will only return bool (i hope) */
  Future<dynamic> launchWebView(BuildContext context) {
    final nav = Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebView(url: url),
      ),
    );
    return nav;
  }

  Future<void> removeToken() async {
    await storeVal('token', null);
  }

  Future<UserModal> getUserProfile() async {
    final query = '''{
  Viewer {
    id
    avatar {
      medium
    }
    name
    bannerImage
  }
}''';

    final String? token = await getVal("token");
    if (token == null) throw new Exception("ERR_COULDNT_GET_TOKEN");


    final res = await Anilist().fetchQuery(query, null, token: token);

    final data = res['Viewer'];
    return UserModal(
      id: data['id'],
      avatar: data['avatar']['medium'],
      name: data['name'],
      banner: data['bannerImage']
    );
  }

  Future<bool> isAnilistLoggedIn() async {
  final token = await getVal('token');
  if(token != null)
   return true;
  return false;
}

}
