import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';
import '../models/user_model.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConfig.tokenKey);
  }

  // User
  Future<void> saveUser(User user) async {
    await _storage.write(key: AppConfig.userKey, value: jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final userData = await _storage.read(key: AppConfig.userKey);
    if (userData != null) {
      try {
        return User.fromJson(jsonDecode(userData));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: AppConfig.userKey);
  }

  // Role
  Future<void> saveRole(String role) async {
    await _storage.write(key: AppConfig.roleKey, value: role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: AppConfig.roleKey);
  }

  Future<void> deleteRole() async {
    await _storage.delete(key: AppConfig.roleKey);
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
