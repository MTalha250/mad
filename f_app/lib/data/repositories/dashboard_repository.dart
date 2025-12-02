import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../datasources/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardData> getDashboard() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.dashboard);
      return DashboardData.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<DashboardData> getUserDashboard() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userDashboard);
      return DashboardData.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
