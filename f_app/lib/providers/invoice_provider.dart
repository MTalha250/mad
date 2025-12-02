import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/invoice_model.dart';
import '../data/repositories/invoice_repository.dart';
import 'auth_provider.dart';

// Invoice Repository Provider
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InvoiceRepository(apiClient);
});

// Invoices State
class InvoicesState {
  final List<Invoice> invoices;
  final bool isLoading;
  final String? error;
  final String? selectedStatus;
  final String? selectedPaymentTerms;
  final String searchQuery;

  const InvoicesState({
    this.invoices = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
    this.selectedPaymentTerms,
    this.searchQuery = '',
  });

  InvoicesState copyWith({
    List<Invoice>? invoices,
    bool? isLoading,
    String? error,
    String? selectedStatus,
    String? selectedPaymentTerms,
    String? searchQuery,
  }) {
    return InvoicesState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedPaymentTerms: selectedPaymentTerms ?? this.selectedPaymentTerms,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Invoice> get filteredInvoices {
    var filtered = invoices;

    // Filter by status
    if (selectedStatus != null && selectedStatus!.isNotEmpty && selectedStatus != 'All') {
      filtered = filtered.where((i) => i.status == selectedStatus).toList();
    }

    // Filter by payment terms
    if (selectedPaymentTerms != null && selectedPaymentTerms!.isNotEmpty && selectedPaymentTerms != 'All') {
      filtered = filtered.where((i) => i.paymentTerms == selectedPaymentTerms).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((i) {
        return i.invoiceReference.toLowerCase().contains(query) ||
            i.amount.toLowerCase().contains(query) ||
            (i.project?.clientName.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }
}

// Invoices Notifier
class InvoicesNotifier extends StateNotifier<InvoicesState> {
  final InvoiceRepository _repository;

  InvoicesNotifier(this._repository) : super(const InvoicesState());

  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final invoices = await _repository.getInvoices();
      print('Provider received ${invoices.length} invoices');
      state = state.copyWith(invoices: invoices, isLoading: false);
      print('State updated, invoices in state: ${state.invoices.length}');
    } catch (e) {
      print('Error loading invoices: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadOverdueInvoices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final invoices = await _repository.getOverdueInvoices();
      state = state.copyWith(invoices: invoices, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Invoice?> createInvoice(CreateInvoiceRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final invoice = await _repository.createInvoice(request);
      state = state.copyWith(
        invoices: [invoice, ...state.invoices],
        isLoading: false,
      );
      return invoice;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Invoice?> updateInvoice(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final invoice = await _repository.updateInvoice(id, data);
      final updatedInvoices = state.invoices.map((i) {
        return i.id == id ? invoice : i;
      }).toList();
      state = state.copyWith(invoices: updatedInvoices, isLoading: false);
      return invoice;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteInvoice(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteInvoice(id);
      final updatedInvoices = state.invoices.where((i) => i.id != id).toList();
      state = state.copyWith(invoices: updatedInvoices, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(selectedStatus: status);
  }

  void setPaymentTermsFilter(String? terms) {
    state = state.copyWith(selectedPaymentTerms: terms);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Invoices Provider
final invoicesProvider = StateNotifierProvider<InvoicesNotifier, InvoicesState>((ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return InvoicesNotifier(repository);
});

// Single Invoice Provider
final invoiceByIdProvider = FutureProvider.family<Invoice?, String>((ref, id) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  try {
    return await repository.getInvoiceById(id);
  } catch (_) {
    return null;
  }
});
