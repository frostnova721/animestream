import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:http/http.dart';

class Simkl {

  Future<dynamic> search(String query) async {
    final url = "https://api.simkl.com/search/anime?q=$query&client_id=$simklClientId";
    final res = await fetch(url);
  }

  Future<dynamic> fetch(String url) async {
    final res = await get(Uri.parse(url));

    //since 2** means success
    if(res.statusCode < 200 || res.statusCode > 299) {
      throw Exception("ERR_COULDNT_FETCH_SIMKL");
    }

    return res.body;
  }
}