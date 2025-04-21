import 'package:animestream/core/anime/providers/bridge.dart';
import 'package:animestream/core/anime/providers/registers/html.dart';
import 'package:animestream/core/anime/providers/registers/http.dart';
import 'package:animestream/core/anime/providers/types.dart';
import 'package:dart_eval/dart_eval.dart';
void run() async {

  final ps = '''
import 'package:test/main.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';

class TP extends AnimeProvider {

  @override
  String providerName = "testProvider";

  @override
  Future<List<String>> getAnimeEpisodeLink(String aliasId) {
    throw UnimplementedError();
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream> p1, bool p2) update) {
    throw UnimplementedError();
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream> p1, bool p2) update) {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    // final res = await get(Uri.parse("https://icey-api.vercel.app/pin/search?q=anime"), headers: {"hey": "hey"});
    final doc = parse('<html><body><div class="hi"><p class="hm">diddied!</p></div><div class="hello"><p class="text">HEY there!</p></div></body></html>');
    print(doc.body.querySelector(".hi").children[1]);
    return [];
  }
  
}
AnimeProvider createProvider() {
  return TP();
}

''';

  final Compiler compiler = Compiler();
  compiler.defineBridgeClass($AnimeProvider$bridge.$declaration);
  compiler.addPlugin(HttpPlugin());
  compiler.addPlugin(HtmlPlugin());

  final pgm = compiler.compile({
    'test': {"main.dart": ps}
  });

  final runtime = Runtime.ofProgram(pgm);
  runtime.registerBridgeFunc("package:test/main.dart", "AnimeProvider.", $AnimeProvider$bridge.$new, isBridge: true);
  runtime.addPlugin(HttpPlugin());
  runtime.addPlugin(HtmlPlugin());
  final AnimeProvider res = runtime.executeLib("package:test/main.dart", "createProvider");

  await res.search("hii");
}
