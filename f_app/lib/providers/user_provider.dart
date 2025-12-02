import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import 'auth_provider.dart';

// User Repository Provider
final usersRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepository(apiClient);
});

// Users State
class UsersState {
  final List<User> users;
  final List<User> pendingUsers;
  final List<User> approvedUsers;
  final bool isLoading;
  final String? error;

  const UsersState({
    this.users = const [],
    this.pendingUsers = const [],
    this.approvedUsers = const [],
    this.isLoading = false,
    this.error,
  });

  UsersState copyWith({
    List<User>? users,
    List<User>? pendingUsers,
    List<User>? approvedUsers,
    bool? isLoading,
    String? error,
  }) {
    return UsersState(
      users: users ?? this.users,
      pendingUsers: pendingUsers ?? this.pendingUsers,
      approvedUsers: approvedUsers ?? this.approvedUsers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Users Notifier
class UsersNotifier extends StateNotifier<UsersState> {
  final UserRepository _repository;

  UsersNotifier(this._repository) : super(const UsersState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repository.getUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPendingUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repository.getPendingUsers();
      state = state.copyWith(pendingUsers: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadApprovedUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repository.getApprovedUsers();
      state = state.copyWith(approvedUsers: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAllUsersData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pending = await _repository.getPendingUsers();
      final approved = await _repository.getApprovedUsers();
      state = state.copyWith(
        pendingUsers: pending,
        approvedUsers: approved,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approveUser(String id) async {
    try {
      await _repository.approveUser(id);
      // Move user from pending to approved
      final user = state.pendingUsers.firstWhere((u) => u.id == id);
      final updatedPending = state.pendingUsers.where((u) => u.id != id).toList();
      final updatedApproved = [user.copyWith(status: 'Approved'), ...state.approvedUsers];
      state = state.copyWith(pendingUsers: updatedPending, approvedUsers: updatedApproved);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> rejectUser(String id) async {
    try {
      await _repository.rejectUser(id);
      final updatedPending = state.pendingUsers.where((u) => u.id != id).toList();
      state = state.copyWith(pendingUsers: updatedPending);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _repository.deleteUser(id);
      final updatedPending = state.pendingUsers.where((u) => u.id != id).toList();
      final updatedApproved = state.approvedUsers.where((u) => u.id != id).toList();
      final updatedUsers = state.users.where((u) => u.id != id).toList();
      state = state.copyWith(
        pendingUsers: updatedPending,
        approvedUsers: updatedApproved,
        users: updatedUsers,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Users Provider
final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final repository = ref.watch(usersRepositoryProvider);
  return UsersNotifier(repository);
});
