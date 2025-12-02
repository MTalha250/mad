import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/common/loading_indicator.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadUserDashboard();
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(dashboardProvider.notifier).loadUserDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.profile),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                user?.initials ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashboardState.isLoading && dashboardState.data == null
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Text(
                      'Welcome, ${user?.name.split(' ').first ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Here are your assigned tasks',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    _buildStatsGrid(dashboardState.data),
                    const SizedBox(height: 24),

                    // Assigned Projects
                    _buildAssignedSection(
                      title: 'Assigned Projects',
                      items: dashboardState.data?.recentProjects ?? [],
                      onViewAll: () => context.go(AppRoutes.userProjects),
                      itemBuilder: (project) => _buildProjectItem(project),
                      emptyMessage: 'No projects assigned to you',
                    ),
                    const SizedBox(height: 16),

                    // Assigned Complaints
                    _buildAssignedSection(
                      title: 'Assigned Complaints',
                      items: dashboardState.data?.recentComplaints ?? [],
                      onViewAll: () => context.go(AppRoutes.userComplaints),
                      itemBuilder: (complaint) => _buildComplaintItem(complaint),
                      emptyMessage: 'No complaints assigned to you',
                    ),
                    const SizedBox(height: 16),

                    // Assigned Maintenances
                    _buildAssignedSection(
                      title: 'Assigned Maintenances',
                      items: dashboardState.data?.recentMaintenances ?? [],
                      onViewAll: () => context.go(AppRoutes.userMaintenances),
                      itemBuilder: (maintenance) => _buildMaintenanceItem(maintenance),
                      emptyMessage: 'No maintenances assigned to you',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid(data) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        StatCard(
          title: 'Projects',
          value: (data?.projectCount ?? 0).toString(),
          icon: Icons.folder_outlined,
          iconColor: AppColors.primary,
          onTap: () => context.go(AppRoutes.userProjects),
        ),
        StatCard(
          title: 'Complaints',
          value: (data?.complaintCount ?? 0).toString(),
          icon: Icons.report_problem_outlined,
          iconColor: AppColors.warning,
          onTap: () => context.go(AppRoutes.userComplaints),
        ),
        StatCard(
          title: 'Maintenance',
          value: (data?.maintenanceCount ?? 0).toString(),
          icon: Icons.build_outlined,
          iconColor: AppColors.info,
          onTap: () => context.go(AppRoutes.userMaintenances),
        ),
      ],
    );
  }

  Widget _buildAssignedSection<T>({
    required String title,
    required List<T> items,
    required VoidCallback onViewAll,
    required Widget Function(T) itemBuilder,
    required String emptyMessage,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        emptyMessage,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length > 5 ? 5 : items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) => itemBuilder(items[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectItem(dynamic project) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        project.clientName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        project.dueDate != null
            ? 'Due: ${DateFormatter.formatDate(project.dueDate)}'
            : 'No due date',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: StatusBadge(status: project.status),
      onTap: () => context.push('/home/projects/${project.id}'),
    );
  }

  Widget _buildComplaintItem(dynamic complaint) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        complaint.clientName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        complaint.complaintReference.isNotEmpty
            ? complaint.complaintReference
            : 'No reference',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: StatusBadge(status: complaint.status),
      onTap: () => context.push('/home/complaints/${complaint.id}'),
    );
  }

  Widget _buildMaintenanceItem(dynamic maintenance) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        maintenance.clientName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${maintenance.serviceDateCount} service dates',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: StatusBadge(status: maintenance.status),
      onTap: () => context.push('/home/maintenances/${maintenance.id}'),
    );
  }
}
