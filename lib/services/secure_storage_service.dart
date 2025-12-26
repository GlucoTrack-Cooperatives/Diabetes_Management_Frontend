//  Save the jwt token

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storageServiceProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'role';

  // Save Token n Role
  Future<void> saveCredentials(String token, String role) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
  }

  // Get Token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  // Delete Token (Logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}