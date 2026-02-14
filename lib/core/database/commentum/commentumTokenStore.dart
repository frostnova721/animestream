import 'package:commentum_client/commentum_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CommentumTokenStore extends CommentumStorage {
  String _providerKey(CommentumProvider provider) => "commentum_${provider.name}_token";

  final _fss = const FlutterSecureStorage();

  @override
  Future<void> clearAll() async {
    for (final provider in CommentumProvider.values) {
      await _fss.delete(key: _providerKey(provider));
    }
  }

  @override
  Future<void> deleteToken(CommentumProvider provider) {
    return _fss.delete(key: _providerKey(provider));
  }

  @override
  Future<String?> getToken(CommentumProvider provider) {
    return _fss.read(key: _providerKey(provider));
  }

  @override
  Future<void> saveToken(CommentumProvider provider, String token) {
    return _fss.write(key: _providerKey(provider), value: token);
  }
}
