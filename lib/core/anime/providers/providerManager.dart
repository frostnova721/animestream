import 'dart:convert';

import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:animestream/core/data/providers.dart';
import 'package:http/http.dart';

class ProviderManager {
  static const String _fileBaseUrl = "https://raw.githubusercontent.com/frostnova721/provins/master/lib/providers/";

  static const String _indexUrl = "https://raw.githubusercontent.com/frostnova721/provins/master/index.json";

  final _providersPreferences = ProvidersPreferences();

  /// Get the saved(Installed) provider's code.
  Future<String?> getSavedProviderCode(String providerIdentifier) async {
    return (await _providersPreferences.getProvider(providerIdentifier))?.code;
  }

  /// Get the list of all saved providers.
  Future<List<ProviderDetails>> getSavedProviders() async {
    return await _providersPreferences.listAllProviders();
  }

  /// Save/Install a provider.
  Future<void> saveProvider(ProviderDetails provider) async {
    return await _providersPreferences.saveProvider(provider);
  }

  /// Remove/Uninstall a provider.
  Future<void> removeProvider(ProviderDetails provider) async {
    return await _providersPreferences.removeProvider(provider.identifier);
  }

  /// Fetch the code for the provider from the repo.
  Future<String?> fetchProviderCode(String providerIdentifier) async {
    final url = _fileBaseUrl + "$providerIdentifier/$providerIdentifier.dart";
    final res = await get(Uri.parse(url));
    return res.statusCode == 200 ? res.body : null;
  }

  /// Yeah, fetch the repo.
  Future<List<ProviderDetails>> fetchProvidersRepo() async {
    final availableProviders = await get(Uri.parse(_indexUrl));
    final List<dynamic> jsoned = jsonDecode(availableProviders.body) as List<dynamic>;
    final List<Map<String, String?>> mapped = jsoned.map((e) => Map.from(e as Map).cast<String, String?>()).toList();
    final classed = mapped.map((e) => ProviderDetails.fromMap(e)).toList();
    return classed;
  }
}
