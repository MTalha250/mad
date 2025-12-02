import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../datasources/api_client.dart';
import '../models/complaint_model.dart';

class ComplaintRepository {
  final ApiClient _apiClient;

  ComplaintRepository(this._apiClient);

  Future<List<Complaint>> getComplaints() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.complaints);
      final data = response.data;
      final List<dynamic> complaints = data is List ? data : (data['complaints'] ?? []);
      return complaints.map((e) => Complaint.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Complaint>> getUserComplaints() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userComplaints);
      final data = response.data;
      final List<dynamic> complaints = data is List ? data : (data['complaints'] ?? []);
      return complaints.map((e) => Complaint.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Complaint>> getComplaintsByStatus(String status) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.complaintsByStatus(status));
      final data = response.data;
      final List<dynamic> complaints = data is List ? data : (data['complaints'] ?? []);
      return complaints.map((e) => Complaint.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Complaint>> getComplaintsByPriority(String priority) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.complaintsByPriority(priority));
      final data = response.data;
      final List<dynamic> complaints = data is List ? data : (data['complaints'] ?? []);
      return complaints.map((e) => Complaint.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Complaint> getComplaintById(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.complaintById(id));
      return Complaint.fromJson(response.data['complaint'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Complaint> createComplaint(CreateComplaintRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.complaints,
        data: request.toJson(),
      );
      return Complaint.fromJson(response.data['complaint'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Complaint> updateComplaint(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.complaintById(id),
        data: data,
      );
      return Complaint.fromJson(response.data['complaint'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteComplaint(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.complaintById(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> assignUsers(String id, List<String> userIds) async {
    try {
      await _apiClient.post(
        ApiEndpoints.assignComplaintUsers(id),
        data: {'userIds': userIds},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
