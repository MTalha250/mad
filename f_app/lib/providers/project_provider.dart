import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/project_model.dart';
import '../data/repositories/project_repository.dart';
import 'auth_provider.dart';

// Project Repository Provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProjectRepository(apiClient);
});

// Projects State
class ProjectsState {
  final List<Project> projects;
  final bool isLoading;
  final String? error;
  final String? selectedStatus;
  final String searchQuery;

  const ProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
    this.searchQuery = '',
  });

  ProjectsState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? error,
    String? selectedStatus,
    String? searchQuery,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Project> get filteredProjects {
    var filtered = projects;

    // Filter by status
    if (selectedStatus != null && selectedStatus!.isNotEmpty && selectedStatus != 'All') {
      filtered = filtered.where((p) => p.status == selectedStatus).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.clientName.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query) ||
            p.po.value.toLowerCase().contains(query) ||
            p.quotation.value.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }
}

// Projects Notifier
class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final ProjectRepository _repository;

  ProjectsNotifier(this._repository) : super(const ProjectsState());

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final projects = await _repository.getProjects();
      state = state.copyWith(projects: projects, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUserProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final projects = await _repository.getUserProjects();
      state = state.copyWith(projects: projects, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Project?> createProject(CreateProjectRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final project = await _repository.createProject(request);
      state = state.copyWith(
        projects: [project, ...state.projects],
        isLoading: false,
      );
      return project;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Project?> updateProject(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final project = await _repository.updateProject(id, data);
      final updatedProjects = state.projects.map((p) {
        return p.id == id ? project : p;
      }).toList();
      state = state.copyWith(projects: updatedProjects, isLoading: false);
      return project;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteProject(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteProject(id);
      final updatedProjects = state.projects.where((p) => p.id != id).toList();
      state = state.copyWith(projects: updatedProjects, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> assignUsers(String id, List<String> userIds) async {
    try {
      await _repository.assignUsers(id, userIds);
      await loadProjects();
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

// Projects Provider
final projectsProvider = StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return ProjectsNotifier(repository);
});

// Single Project Provider
final projectByIdProvider = FutureProvider.family<Project?, String>((ref, id) async {
  final repository = ref.watch(projectRepositoryProvider);
  try {
    return await repository.getProjectById(id);
  } catch (_) {
    return null;
  }
});
