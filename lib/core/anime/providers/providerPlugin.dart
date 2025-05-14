import 'package:animestream/core/anime/providers/animeProvider.dart';
import 'package:animestream/core/anime/providers/animepahe.dart';
import 'package:animestream/core/anime/providers/providerManager.dart';

class ProviderPlugin {
  late dynamic _compiler;

  ProviderPlugin() {
    _setupCompiler();
  }

  final Map<String, AnimeProvider> _compiledProviders = {};

  void _setupCompiler() {
    
  }

  Future<AnimeProvider?> getProvider(String provider, { String? testCode}) async {
    if(provider.isEmpty && testCode == null) return null;
    
    final cachedProvider = _compiledProviders[provider];
    if(cachedProvider != null) return cachedProvider; 

    print("Cache miss. compiling provider.");

    final program = testCode != null ? testCode : await ProviderManager().getSavedProviderCode(provider);

    if(program == null) return null;

    return AnimePahe();
  }
}
