import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../datasources/api_client.dart';
import '../models/invoice_model.dart';

class InvoiceRepository {
  final ApiClient _apiClient;

  InvoiceRepository(this._apiClient);

  Future<List<Invoice>> getInvoices() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.invoices);
      final data = response.data;
      final List<dynamic> invoices = data is List ? data : (data['invoices'] ?? []);
      return invoices.map((e) => Invoice.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Invoice>> getOverdueInvoices() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.overdueInvoices);
      final data = response.data;
      final List<dynamic> invoices = data is List ? data : (data['invoices'] ?? []);
      return invoices.map((e) => Invoice.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Invoice>> getInvoicesByStatus(String status) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.invoicesByStatus(status));
      final data = response.data;
      final List<dynamic> invoices = data is List ? data : (data['invoices'] ?? []);
      return invoices.map((e) => Invoice.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Invoice>> getInvoicesByPaymentTerms(String terms) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.invoicesByPaymentTerms(terms));
      final data = response.data;
      final List<dynamic> invoices = data is List ? data : (data['invoices'] ?? []);
      return invoices.map((e) => Invoice.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Invoice>> getInvoicesByProject(String projectId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.invoicesByProject(projectId));
      final data = response.data;
      final List<dynamic> invoices = data is List ? data : (data['invoices'] ?? []);
      return invoices.map((e) => Invoice.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Invoice> getInvoiceById(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.invoiceById(id));
      return Invoice.fromJson(response.data['invoice'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Invoice> createInvoice(CreateInvoiceRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.invoices,
        data: request.toJson(),
      );
      return Invoice.fromJson(response.data['invoice'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Invoice> updateInvoice(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.invoiceById(id),
        data: data,
      );
      return Invoice.fromJson(response.data['invoice'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.invoiceById(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
