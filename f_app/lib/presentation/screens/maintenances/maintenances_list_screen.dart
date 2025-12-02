import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../providers/maintenance_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/inputs/input_field.dart';

class MaintenancesListScreen extends ConsumerStatefulWidget {
  const MaintenancesListScreen({super.key});

  @override
  ConsumerState<MaintenancesListScreen> createState() => _MaintenancesListScreenState();
}

class _MaintenancesListScreenState extends ConsumerState<MaintenancesListScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(maintenancesProvider.notifier).loadMaintenances();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(maintenancesProvider.notifier).loadMaintenances();
  }

  @override
  Widget build(BuildContext context) {
    final maintenancesState = ref.watch(maintenancesProvider);
    final filteredMaintenances = maintenancesState.filteredMaintenances;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenances'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.createMaintenance),
            icon: const Icon(Icons.add),
            tooltip: 'Create Maintenance',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                InputField(
                  controller: _searchController,
                  hint: 'Search maintenances...',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    ref.read(maintenancesProvider.notifier).setSearchQuery(value);
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Pending', 'In Progress', 'Completed', 'Cancelled']
                        .map((status) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(status),
                                selected: _selectedStatus == status,
                                onSelected: (selected) {
                                  setState(() => _selectedStatus = status);
                                  ref.read(maintenancesProvider.notifier).setStatusFilter(
                                        status == 'All' ? null : status,
                                      );
                                },
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.primary,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Maintenances List
          Expanded(
            child: maintenancesState.isLoading && maintenancesState.maintenances.isEmpty
                ? const ShimmerLoading()
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.primary,
                    child: filteredMaintenances.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.build_outlined,
                                      size: 64,
                                      color: AppColors.textTertiary,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No maintenances found',
                                      style: TextStyle(
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
                            itemCount: filteredMaintenances.length,
                            itemBuilder: (context, index) {
                              final maintenance = filteredMaintenances[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    maintenance.clientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (maintenance.remarks.value.isNotEmpty)
                                        Text(
                                          maintenance.remarks.value,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (maintenance.serviceDateCount > 0) ...[
                                            const Icon(
                                              Icons.calendar_month,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${maintenance.serviceDateCount} service dates',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                          ],
                                          if (maintenance.completedCount > 0 || maintenance.pendingCount > 0) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${maintenance.completedCount}/${maintenance.serviceDateCount}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.success,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: StatusBadge(status: maintenance.status),
                                  onTap: () => context.push('/home/maintenances/${maintenance.id}'),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
