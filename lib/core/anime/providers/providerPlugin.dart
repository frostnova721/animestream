import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/bridge.dart';
import 'package:animestream/core/anime/providers/providerManager.dart';
import 'package:animestream/core/anime/providers/registers/html.dart';
import 'package:animestream/core/anime/providers/registers/http.dart';
import 'package:animestream/core/anime/providers/type/videoStream.dart';
import 'package:dart_eval/dart_eval.dart';

class ProviderPlugin {
  late Compiler _compiler;

  ProviderPlugin() {
    _setupCompiler();
  }

  void _setupCompiler() {
    _compiler = Compiler();

    _compiler.defineBridgeClass($AnimeProvider$bridge.$declaration);
    _compiler.defineBridgeClass($VideoStream.$declaration);

    _compiler.addPlugin(HttpPlugin());
    _compiler.addPlugin(HtmlPlugin());
  }

  Future<AnimeProvider?> getProvider(String provider) async {
    final program = await ProviderManager().getSavedProviderCode(provider);

    if(program == null) return null;

    final pgm = _compiler.compile({
      'test': {"main.dart": program}
    });

    final runtime = Runtime.ofProgram(pgm);
    runtime.registerBridgeFunc("package:provins/classes.dart", "AnimeProvider.", $AnimeProvider$bridge.$new, isBridge: true);
    runtime.registerBridgeFunc("package:provins/classes.dart", "VideoStream.", $VideoStream.$new, isBridge: false);
    runtime.addPlugin(HttpPlugin());
    runtime.addPlugin(HtmlPlugin());
    final AnimeProvider res = runtime.executeLib("package:test/main.dart", "createProvider");
    return res;
  }
}
