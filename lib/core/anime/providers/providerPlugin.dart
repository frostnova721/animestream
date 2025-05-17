import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/apRemote.dart';
import 'package:animestream/core/anime/providers/bridge.dart';
import 'package:animestream/core/anime/providers/providerManager.dart';
import 'package:animestream/core/anime/providers/registers/html.dart';
import 'package:animestream/core/anime/providers/registers/http.dart';
import 'package:d4rt/d4rt.dart';

class ProviderPlugin {

  ProviderPlugin() {
    _setupCompiler();
  }

  final Map<String, AnimeProvider> _compiledProviders = {};

  void _setupCompiler() {}

  Future<AnimeProvider?> getProvider(String provider, {String? testCode}) async {
    if (provider.isEmpty && testCode == null) return null;

    final cachedProvider = _compiledProviders[provider];
    if (cachedProvider != null) return cachedProvider;

    print("Cache miss. compiling provider.");

    final program = testCode != null ? testCode : await ProviderManager().getSavedProviderCode(provider);

    if (program == null) return null;

    final d4rt = D4rt();

    d4rt.registerBridgedClass(AnimeProviderBridge.$bridger);
    d4rt.registerBridgedClass(AnimeProviderBridge.videoStreamBridge);
    HttpRegisters.register(d4rt);
    HtmlRegister().register(d4rt);

    await d4rt.execute(rc());

    return APWrapper(d4rt);
  }
}
