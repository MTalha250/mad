import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../datasources/api_client.dart';
import '../datasources/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthRepository(this._apiClient, this._storage);

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );
      final authResponse = AuthResponse.fromJson(response.data);

      // Save to secure storage
      await _storage.saveToken(authResponse.token);
      await _storage.saveUser(authResponse.user);
      await _storage.saveRole(authResponse.user.role);

      return authResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse> register(SignUpRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<User> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.profile);
      return User.fromJson(response.data['user'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<User> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.profile,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
        },
      );
      final user = User.fromJson(response.data['user'] ?? response.data);
      await _storage.saveUser(user);
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> verifyResetCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.verifyResetCode,
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> resetPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.put(
        ApiEndpoints.resetPassword,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  Future<String?> getToken() async {
    return await _storage.getToken();
  }

  Future<User?> getSavedUser() async {
    return await _storage.getUser();
  }

  Future<String?> getSavedRole() async {
    return await _storage.getRole();
  }

  // Try to restore session from saved token
  Future<User?> restoreSession() async {
    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      // Verify token is still valid by fetching profile
      final user = await getProfile();
      await _storage.saveUser(user);
      await _storage.saveRole(user.role);
      return user;
    } catch (_) {
      // Token invalid, clear storage
      await _storage.clearAll();
      return null;
    }
  }
}
