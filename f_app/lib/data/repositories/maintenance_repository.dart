import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../datasources/api_client.dart';
import '../models/maintenance_model.dart';

class MaintenanceRepository {
  final ApiClient _apiClient;

  MaintenanceRepository(this._apiClient);

  Future<List<Maintenance>> getMaintenances() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.maintenances);
      final data = response.data;
      final List<dynamic> maintenances = data is List ? data : (data['maintenances'] ?? []);
      return maintenances.map((e) => Maintenance.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Maintenance>> getUserMaintenances() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userMaintenances);
      final data = response.data;
      final List<dynamic> maintenances = data is List ? data : (data['maintenances'] ?? []);
      return maintenances.map((e) => Maintenance.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Maintenance>> getUpcomingMaintenances() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.upcomingMaintenances);
      final data = response.data;
      final List<dynamic> maintenances = data is List ? data : (data['maintenances'] ?? []);
      return maintenances.map((e) => Maintenance.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Maintenance>> getMaintenancesByStatus(String status) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.maintenancesByStatus(status));
      final data = response.data;
      final List<dynamic> maintenances = data is List ? data : (data['maintenances'] ?? []);
      return maintenances.map((e) => Maintenance.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Maintenance> getMaintenanceById(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.maintenanceById(id));
      return Maintenance.fromJson(response.data['maintenance'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Maintenance> createMaintenance(CreateMaintenanceRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.maintenances,
        data: request.toJson(),
      );
      return Maintenance.fromJson(response.data['maintenance'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Maintenance> updateMaintenance(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.maintenanceById(id),
        data: data,
      );
      return Maintenance.fromJson(response.data['maintenance'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteMaintenance(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.maintenanceById(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> assignUsers(String id, List<String> userIds) async {
    try {
      await _apiClient.post(
        ApiEndpoints.assignMaintenanceUsers(id),
        data: {'userIds': userIds},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
