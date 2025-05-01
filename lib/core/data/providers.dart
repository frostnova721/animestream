import 'package:animestream/core/anime/providers/providerDetails.dart';
import 'package:hive/hive.dart';

class ProvidersPreferences {
  final _boxKey = "anime_providers";

  Future<ProviderDetails?> getProvider(String identifier) async {
    final box = await Hive.openBox(_boxKey);
    final Map<String, String?>? provider = (await box.get(identifier) as Map).cast();
    await box.close();
    return ProviderDetails?.fromMap(provider!);
  }

  Future<List<ProviderDetails>> listAllProviders() async {
    final box = await Hive.openBox(_boxKey);
    final List<dynamic> providers = await box.values.toList();
    final List<Map<String, String?>> mappedList = providers.map((it) => Map.from(it as Map).cast<String, String?>()).toList();
    await box.close();
    return mappedList.map((e) => ProviderDetails.fromMap(e)).toList();
  }

  Future<void> saveProvider(ProviderDetails provider) async {
    final box = await Hive.openBox(_boxKey);
    await box.put(provider.identifier, provider.toMap());
    await box.close();
  }

  Future<void> removeProvider(String identifier) async {
    final box = await Hive.openBox(_boxKey);
    await box.delete(identifier);
    await box.close();
  }
}
