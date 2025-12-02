import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/complaint_model.dart';
import '../data/repositories/complaint_repository.dart';
import 'auth_provider.dart';

// Complaint Repository Provider
final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ComplaintRepository(apiClient);
});

// Complaints State
class ComplaintsState {
  final List<Complaint> complaints;
  final bool isLoading;
  final String? error;
  final String? selectedStatus;
  final String? selectedPriority;
  final String searchQuery;

  const ComplaintsState({
    this.complaints = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
    this.selectedPriority,
    this.searchQuery = '',
  });

  ComplaintsState copyWith({
    List<Complaint>? complaints,
    bool? isLoading,
    String? error,
    String? selectedStatus,
    String? selectedPriority,
    String? searchQuery,
  }) {
    return ComplaintsState(
      complaints: complaints ?? this.complaints,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedPriority: selectedPriority ?? this.selectedPriority,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Complaint> get filteredComplaints {
    var filtered = complaints;

    // Filter by status
    if (selectedStatus != null && selectedStatus!.isNotEmpty && selectedStatus != 'All') {
      filtered = filtered.where((c) => c.status == selectedStatus).toList();
    }

    // Filter by priority
    if (selectedPriority != null && selectedPriority!.isNotEmpty && selectedPriority != 'All') {
      filtered = filtered.where((c) => c.priority == selectedPriority).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.clientName.toLowerCase().contains(query) ||
            c.complaintReference.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }
}

// Complaints Notifier
class ComplaintsNotifier extends StateNotifier<ComplaintsState> {
  final ComplaintRepository _repository;

  ComplaintsNotifier(this._repository) : super(const ComplaintsState());

  Future<void> loadComplaints() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final complaints = await _repository.getComplaints();
      state = state.copyWith(complaints: complaints, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUserComplaints() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final complaints = await _repository.getUserComplaints();
      state = state.copyWith(complaints: complaints, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Complaint?> createComplaint(CreateComplaintRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final complaint = await _repository.createComplaint(request);
      state = state.copyWith(
        complaints: [complaint, ...state.complaints],
        isLoading: false,
      );
      return complaint;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Complaint?> updateComplaint(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final complaint = await _repository.updateComplaint(id, data);
      final updatedComplaints = state.complaints.map((c) {
        return c.id == id ? complaint : c;
      }).toList();
      state = state.copyWith(complaints: updatedComplaints, isLoading: false);
      return complaint;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteComplaint(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteComplaint(id);
      final updatedComplaints = state.complaints.where((c) => c.id != id).toList();
      state = state.copyWith(complaints: updatedComplaints, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> assignUsers(String id, List<String> userIds) async {
    try {
      await _repository.assignUsers(id, userIds);
      await loadComplaints();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(selectedStatus: status);
  }

  void setPriorityFilter(String? priority) {
    state = state.copyWith(selectedPriority: priority);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Complaints Provider
final complaintsProvider = StateNotifierProvider<ComplaintsNotifier, ComplaintsState>((ref) {
  final repository = ref.watch(complaintRepositoryProvider);
  return ComplaintsNotifier(repository);
});

// Single Complaint Provider
final complaintByIdProvider = FutureProvider.family<Complaint?, String>((ref, id) async {
  final repository = ref.watch(complaintRepositoryProvider);
  try {
    return await repository.getComplaintById(id);
  } catch (_) {
    return null;
  }
});
