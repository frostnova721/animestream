import 'package:animestream/core/commons/enums.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<String?> getSecureVal(SecureStorageKey key) async {
  final st = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  final item = await st.read(key: key.value);
  return item;
}