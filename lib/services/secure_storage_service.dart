//  Save the jwt token

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storageServiceProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'user_role';
  static const _userIdKey = 'user_id';

  // Save Token, role and userId
  Future<void> saveCredentials(String token, String role, String userId) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _userIdKey, value: userId);
  }

  // Get Token
  Future<String?> getToken() async => await _storage.read(key: _tokenKey);
  Future<String?> getRole() async => await _storage.read(key: _roleKey);
  Future<String?> getUserId() async => await _storage.read(key: _userIdKey);

  // Delete Token (Logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}