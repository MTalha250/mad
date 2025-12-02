import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../datasources/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<List<User>> getUsers() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.users);
      final data = response.data;
      final List<dynamic> users = data is List ? data : (data['users'] ?? []);
      return users.map((e) => User.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<User>> getPendingUsers() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.pendingUsers);
      final data = response.data;
      final List<dynamic> users = data is List ? data : (data['users'] ?? []);
      return users.map((e) => User.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<User>> getApprovedUsers() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.approvedUsers);
      final data = response.data;
      final List<dynamic> users = data is List ? data : (data['users'] ?? []);
      return users.map((e) => User.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<User> approveUser(String id) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.pendingUserById(id),
        data: {'status': 'Approved'},
      );
      return User.fromJson(response.data['user'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<User> rejectUser(String id) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.pendingUserById(id),
        data: {'status': 'Rejected'},
      );
      return User.fromJson(response.data['user'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.userById(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
