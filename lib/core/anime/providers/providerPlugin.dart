import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/bridge.dart';
import 'package:animestream/core/anime/providers/providerManager.dart';
import 'package:animestream/core/anime/providers/registers/html.dart';
import 'package:animestream/core/anime/providers/registers/http.dart';
import 'package:animestream/core/anime/providers/registers/util.dart';
import 'package:animestream/core/anime/providers/type/videoStream.dart';
import 'package:dart_eval/dart_eval.dart';

class ProviderPlugin {
  late Compiler _compiler;

  ProviderPlugin() {
    _setupCompiler();
  }

  final Map<String, AnimeProvider> _compiledProviders = {};

  void _setupCompiler() {
    _compiler = Compiler();

    _compiler.defineBridgeClass($AnimeProvider$bridge.$declaration);
    _compiler.defineBridgeClass($VideoStream.$declaration);

    /// Plug those stuff in (>_<)
    _compiler.addPlugin(HttpPlugin());
    _compiler.addPlugin(HtmlPlugin());
    _compiler.addPlugin(UtilPlugin());
  }

  Future<AnimeProvider?> getProvider(String provider, { String? testCode}) async {
    if(provider.isEmpty && testCode == null) return null;
    
    final cachedProvider = _compiledProviders[provider];
    if(cachedProvider != null) return cachedProvider; 

    print("Cache miss. compiling provider.");

    final program = testCode != null ? testCode : await ProviderManager().getSavedProviderCode(provider);

    if(program == null) return null;

    final pgm = _compiler.compile({
      'test': {"main.dart": program}
    });

    final runtime = Runtime.ofProgram(pgm);
    runtime.registerBridgeFunc("package:provins/classes.dart", "AnimeProvider.", $AnimeProvider$bridge.$new, isBridge: true);
    runtime.registerBridgeFunc("package:provins/classes.dart", "VideoStream.", $VideoStream.$new, isBridge: false);
    runtime.addPlugin(HttpPlugin());
    runtime.addPlugin(HtmlPlugin());
    runtime.addPlugin(UtilPlugin());
    final AnimeProvider res = runtime.executeLib("package:test/main.dart", "createProvider");
    _compiledProviders[provider] = res;
    return res;
  }
}
