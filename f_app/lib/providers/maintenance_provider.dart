import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/maintenance_model.dart';
import '../data/repositories/maintenance_repository.dart';
import 'auth_provider.dart';

// Maintenance Repository Provider
final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MaintenanceRepository(apiClient);
});

// Maintenances State
class MaintenancesState {
  final List<Maintenance> maintenances;
  final bool isLoading;
  final String? error;
  final String? selectedStatus;
  final String searchQuery;

  const MaintenancesState({
    this.maintenances = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
    this.searchQuery = '',
  });

  MaintenancesState copyWith({
    List<Maintenance>? maintenances,
    bool? isLoading,
    String? error,
    String? selectedStatus,
    String? searchQuery,
  }) {
    return MaintenancesState(
      maintenances: maintenances ?? this.maintenances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Maintenance> get filteredMaintenances {
    var filtered = maintenances;

    // Filter by status
    if (selectedStatus != null && selectedStatus!.isNotEmpty && selectedStatus != 'All') {
      filtered = filtered.where((m) => m.status == selectedStatus).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((m) {
        return m.clientName.toLowerCase().contains(query) ||
            m.remarks.value.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }
}

// Maintenances Notifier
class MaintenancesNotifier extends StateNotifier<MaintenancesState> {
  final MaintenanceRepository _repository;

  MaintenancesNotifier(this._repository) : super(const MaintenancesState());

  Future<void> loadMaintenances() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final maintenances = await _repository.getMaintenances();
      state = state.copyWith(maintenances: maintenances, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUserMaintenances() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final maintenances = await _repository.getUserMaintenances();
      state = state.copyWith(maintenances: maintenances, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUpcomingMaintenances() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final maintenances = await _repository.getUpcomingMaintenances();
      state = state.copyWith(maintenances: maintenances, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Maintenance?> createMaintenance(CreateMaintenanceRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final maintenance = await _repository.createMaintenance(request);
      state = state.copyWith(
        maintenances: [maintenance, ...state.maintenances],
        isLoading: false,
      );
      return maintenance;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Maintenance?> updateMaintenance(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final maintenance = await _repository.updateMaintenance(id, data);
      final updatedMaintenances = state.maintenances.map((m) {
        return m.id == id ? maintenance : m;
      }).toList();
      state = state.copyWith(maintenances: updatedMaintenances, isLoading: false);
      return maintenance;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteMaintenance(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteMaintenance(id);
      final updatedMaintenances = state.maintenances.where((m) => m.id != id).toList();
      state = state.copyWith(maintenances: updatedMaintenances, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> assignUsers(String id, List<String> userIds) async {
    try {
      await _repository.assignUsers(id, userIds);
      await loadMaintenances();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(selectedStatus: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Maintenances Provider
final maintenancesProvider = StateNotifierProvider<MaintenancesNotifier, MaintenancesState>((ref) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return MaintenancesNotifier(repository);
});

// Single Maintenance Provider
final maintenanceByIdProvider = FutureProvider.family<Maintenance?, String>((ref, id) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  try {
    return await repository.getMaintenanceById(id);
  } catch (_) {
    return null;
  }
});
