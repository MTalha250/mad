import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/chart/activity_chart.dart';
import '../../widgets/common/loading_indicator.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(dashboardProvider.notifier).loadDashboard();
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
                      'Welcome back, ${user?.name.split(' ').first ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Here\'s what\'s happening today',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    _buildStatsGrid(dashboardState.data),
                    const SizedBox(height: 24),

                    // Activity Chart
                    _buildActivityChart(dashboardState.data),
                    const SizedBox(height: 24),

                    // Recent Projects
                    _buildRecentSection(
                      title: 'Recent Projects',
                      items: dashboardState.data?.recentProjects ?? [],
                      onViewAll: () => context.go(AppRoutes.projects),
                      itemBuilder: (project) => _buildProjectItem(project),
                    ),
                    const SizedBox(height: 16),

                    // Recent Complaints
                    _buildRecentSection(
                      title: 'Recent Complaints',
                      items: dashboardState.data?.recentComplaints ?? [],
                      onViewAll: () => context.go(AppRoutes.complaints),
                      itemBuilder: (complaint) => _buildComplaintItem(complaint),
                    ),
                    const SizedBox(height: 16),

                    // Recent Maintenances
                    _buildRecentSection(
                      title: 'Recent Maintenances',
                      items: dashboardState.data?.recentMaintenances ?? [],
                      onViewAll: () => context.go(AppRoutes.maintenances),
                      itemBuilder: (maintenance) => _buildMaintenanceItem(maintenance),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid(DashboardData? data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          title: 'Active Projects',
          value: (data?.projectCount ?? 0).toString(),
          icon: Icons.folder_outlined,
          iconColor: AppColors.primary,
          onTap: () => context.go(AppRoutes.projects),
        ),
        StatCard(
          title: 'Complaints',
          value: (data?.complaintCount ?? 0).toString(),
          icon: Icons.report_problem_outlined,
          iconColor: AppColors.warning,
          onTap: () => context.go(AppRoutes.complaints),
        ),
        StatCard(
          title: 'Maintenances',
          value: (data?.maintenanceCount ?? 0).toString(),
          icon: Icons.build_outlined,
          iconColor: AppColors.info,
          onTap: () => context.go(AppRoutes.maintenances),
        ),
        StatCard(
          title: 'Invoices',
          value: (data?.invoiceCount ?? 0).toString(),
          icon: Icons.receipt_outlined,
          iconColor: AppColors.success,
          onTap: () => context.go(AppRoutes.invoices),
        ),
      ],
    );
  }

  Widget _buildActivityChart(DashboardData? data) {
    // Generate chart data from dashboard data
    final chartData = _generateChartData(data);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const ChartLegend(),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ActivityChart(data: chartData),
            ),
          ],
        ),
      ),
    );
  }

  List<ChartDataPoint> _generateChartData(DashboardData? data) {
    if (data == null) return [];

    // Group by month
    final Map<String, ChartDataPoint> monthlyData = {};
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // Initialize last 6 months
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = months[date.month - 1];
      monthlyData[key] = ChartDataPoint(month: key);
    }

    // Count projects by month
    for (final project in data.allProjects) {
      if (project.createdAt != null) {
        final month = months[project.createdAt!.month - 1];
        if (monthlyData.containsKey(month)) {
          final current = monthlyData[month]!;
          monthlyData[month] = ChartDataPoint(
            month: month,
            projects: current.projects + 1,
            complaints: current.complaints,
            maintenances: current.maintenances,
          );
        }
      }
    }

    // Count complaints by month
    for (final complaint in data.allComplaints) {
      if (complaint.createdAt != null) {
        final month = months[complaint.createdAt!.month - 1];
        if (monthlyData.containsKey(month)) {
          final current = monthlyData[month]!;
          monthlyData[month] = ChartDataPoint(
            month: month,
            projects: current.projects,
            complaints: current.complaints + 1,
            maintenances: current.maintenances,
          );
        }
      }
    }

    // Count maintenances by month
    for (final maintenance in data.allMaintenances) {
      if (maintenance.createdAt != null) {
        final month = months[maintenance.createdAt!.month - 1];
        if (monthlyData.containsKey(month)) {
          final current = monthlyData[month]!;
          monthlyData[month] = ChartDataPoint(
            month: month,
            projects: current.projects,
            complaints: current.complaints,
            maintenances: current.maintenances + 1,
          );
        }
      }
    }

    return monthlyData.values.toList();
  }

  Widget _buildRecentSection<T>({
    required String title,
    required List<T> items,
    required VoidCallback onViewAll,
    required Widget Function(T) itemBuilder,
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No recent items',
                    style: TextStyle(color: AppColors.textSecondary),
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
