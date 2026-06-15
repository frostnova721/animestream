import 'package:animestream/core/commons/enums.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final Map<String, String?> _secureValCache = {};
final _st = FlutterSecureStorage();

Future<String?> getSecureVal(SecureStorageKey key) async {
  final cached = _secureValCache[key.value];

  if (cached != null) {
    return cached;
  }

  final item = await _st.read(key: key.value);
  _secureValCache[key.value] = item;

  return item;
}

Future<void> storeSecureVal(SecureStorageKey key, String? val) async {
  if (val == null) {
    await _st.delete(key: key.value);
    _secureValCache.remove(key.value);
    return;
  }

  await _st.write(key: key.value, value: val);
  _secureValCache[key.value] = val;
}
