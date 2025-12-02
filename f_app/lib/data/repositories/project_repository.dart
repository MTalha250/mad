import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../datasources/api_client.dart';
import '../models/project_model.dart';

class ProjectRepository {
  final ApiClient _apiClient;

  ProjectRepository(this._apiClient);

  Future<List<Project>> getProjects() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.projects);
      final data = response.data;
      final List<dynamic> projects = data is List ? data : (data['projects'] ?? []);
      return projects.map((e) => Project.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Project>> getUserProjects() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userProjects);
      final data = response.data;
      final List<dynamic> projects = data is List ? data : (data['projects'] ?? []);
      return projects.map((e) => Project.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Project>> getProjectsByStatus(String status) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.projectsByStatus(status));
      final data = response.data;
      final List<dynamic> projects = data is List ? data : (data['projects'] ?? []);
      return projects.map((e) => Project.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Project> getProjectById(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.projectById(id));
      return Project.fromJson(response.data['project'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Project> createProject(CreateProjectRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.projects,
        data: request.toJson(),
      );
      return Project.fromJson(response.data['project'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Project> updateProject(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.projectById(id),
        data: data,
      );
      return Project.fromJson(response.data['project'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.projectById(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> assignUsers(String id, List<String> userIds) async {
    try {
      await _apiClient.post(
        ApiEndpoints.assignProjectUsers(id),
        data: {'userIds': userIds},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
