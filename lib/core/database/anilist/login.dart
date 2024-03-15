import 'package:animestream/core/data/hive.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/models/webView.dart';
import 'package:flutter/material.dart';
import 'package:graphql/client.dart';

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

    final GraphQLClient client = GraphQLClient(
      link: HttpLink("https://graphql.anilist.co",
          defaultHeaders: {'Authorization': 'Bearer $token'}),
      cache: GraphQLCache(),
    );

    final QueryOptions options = QueryOptions(
      document: gql(query),
    );

    final res = await client.query(options);

    if(res.hasException) throw new Exception(res.exception);
    final data = res.data!['Viewer'];
    return UserModal(
      id: data['id'],
      avatar: data['avatar']['medium'],
      name: data['name'],
      banner: data['bannerImage']
    );
  }
}
