import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/inputs/input_field.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';

  final _typeOptions = ['All', 'Directors', 'Admins', 'Heads', 'Users'];
  final _statusOptions = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Load data after widget tree is built
    Future.microtask(() => _loadData());
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      Future.microtask(() => _loadData());
    }
  }

  void _loadData() {
    if (_tabController.index == 0) {
      ref.read(usersProvider.notifier).loadPendingUsers();
    } else {
      ref.read(usersProvider.notifier).loadApprovedUsers();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _loadData();
  }

  List<User> _filterUsers(List<User> users) {
    return users.where((user) {
      // Filter by type
      if (_selectedType != 'All') {
        final role = _selectedType.substring(0, _selectedType.length - 1).toLowerCase();
        if (user.role != role) return false;
      }

      // Filter by status (only for pending tab)
      if (_tabController.index == 0 && _selectedStatus != 'All') {
        if (user.status.toLowerCase() != _selectedStatus.toLowerCase()) return false;
      }

      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final department = user.department;
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.phone.toLowerCase().contains(query) ||
            (department != null && department.toLowerCase().contains(query));
      }

      return true;
    }).toList();
  }

  Future<void> _approveUser(String userId) async {
    final success = await ref.read(usersProvider.notifier).approveUser(userId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User approved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _rejectUser(String userId) async {
    final success = await ref.read(usersProvider.notifier).rejectUser(userId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User rejected'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(usersProvider.notifier).deleteUser(userId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);
    final filteredPendingUsers = _filterUsers(usersState.pendingUsers);
    final filteredApprovedUsers = _filterUsers(usersState.approvedUsers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approvals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Requests'),
            Tab(text: 'Approved Users'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                InputField(
                  controller: _searchController,
                  hint: 'Search by name, email, phone...',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Type Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _typeOptions.map((type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type),
                        selected: _selectedType == type,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = type;
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                      ),
                    )).toList(),
                  ),
                ),
                // Status Filter (only for pending tab)
                if (_tabController.index == 0) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusOptions.map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status),
                          selected: _selectedStatus == status,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                          selectedColor: AppColors.warning.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.warning,
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Users List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pending Requests Tab
                _buildUsersList(
                  filteredPendingUsers,
                  usersState.isLoading && usersState.pendingUsers.isEmpty,
                  isPendingTab: true,
                ),
                // Approved Users Tab
                _buildUsersList(
                  filteredApprovedUsers,
                  usersState.isLoading && usersState.approvedUsers.isEmpty,
                  isPendingTab: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<User> users, bool isLoading, {required bool isPendingTab}) {
    if (isLoading) {
      return const LoadingIndicator();
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: users.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        isPendingTab ? Icons.pending_actions : Icons.people_outline,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPendingTab
                            ? 'No pending requests'
                            : 'No approved users',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserCard(user, isPendingTab);
              },
            ),
    );
  }

  Widget _buildUserCard(User user, bool isPendingTab) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRoleBadge(user.role),
              ],
            ),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final department = user.department;
              return Row(
                children: [
                  if (user.phone.isNotEmpty) ...[
                    const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      user.phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (department != null && department.isNotEmpty) ...[
                    const Icon(Icons.business, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      department,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Joined: ${DateFormatter.formatDate(user.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (isPendingTab)
                  _buildStatusBadge(user.status)
                else
                  _buildStatusBadge('approved'),
              ],
            ),
            const SizedBox(height: 16),
            // Action Buttons
            if (isPendingTab)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectUser(user.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveUser(user.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _deleteUser(user.id, user.name),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Delete User'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bgColor;
    Color textColor;

    switch (role) {
      case 'director':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      case 'admin':
        bgColor = const Color(0xFFF3E8FF);
        textColor = const Color(0xFF6B21A8);
        break;
      case 'head':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        break;
      default:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
    }

    String label;
    switch (role) {
      case 'director':
        label = 'Director';
        break;
      case 'admin':
        label = 'Admin';
        break;
      case 'head':
        label = 'Head';
        break;
      default:
        label = 'User';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = AppColors.statusCompletedBg;
        textColor = AppColors.statusCompletedText;
        break;
      case 'rejected':
        bgColor = AppColors.statusCancelledBg;
        textColor = AppColors.statusCancelledText;
        break;
      default:
        bgColor = AppColors.statusPendingBg;
        textColor = AppColors.statusPendingText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
