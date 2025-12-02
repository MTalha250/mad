import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/complaint_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/badges/priority_badge.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/inputs/input_field.dart';

class ComplaintsListScreen extends ConsumerStatefulWidget {
  const ComplaintsListScreen({super.key});

  @override
  ConsumerState<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends ConsumerState<ComplaintsListScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedPriority = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(complaintsProvider.notifier).loadComplaints();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(complaintsProvider.notifier).loadComplaints();
  }

  @override
  Widget build(BuildContext context) {
    final complaintsState = ref.watch(complaintsProvider);
    final filteredComplaints = complaintsState.filteredComplaints;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.createComplaint),
            icon: const Icon(Icons.add),
            tooltip: 'Create Complaint',
          ),
        ],
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
                  hint: 'Search complaints...',
                  prefixIcon: Icons.search,
                  onChanged: (value) {
                    ref.read(complaintsProvider.notifier).setSearchQuery(value);
                  },
                ),
                const SizedBox(height: 12),
                // Status Filter
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
                                  ref.read(complaintsProvider.notifier).setStatusFilter(
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
                const SizedBox(height: 8),
                // Priority Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Low', 'Medium', 'High']
                        .map((priority) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(priority),
                                selected: _selectedPriority == priority,
                                onSelected: (selected) {
                                  setState(() => _selectedPriority = priority);
                                  ref.read(complaintsProvider.notifier).setPriorityFilter(
                                        priority == 'All' ? null : priority,
                                      );
                                },
                                selectedColor: AppColors.warning.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.warning,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Complaints List
          Expanded(
            child: complaintsState.isLoading && complaintsState.complaints.isEmpty
                ? const ShimmerLoading()
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.primary,
                    child: filteredComplaints.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.report_off_outlined,
                                      size: 64,
                                      color: AppColors.textTertiary,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No complaints found',
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
                            itemCount: filteredComplaints.length,
                            itemBuilder: (context, index) {
                              final complaint = filteredComplaints[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          complaint.clientName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (complaint.complaintReference.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            complaint.complaintReference,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (complaint.description.isNotEmpty)
                                        Text(
                                          complaint.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          PriorityBadge(priority: complaint.priority),
                                          const SizedBox(width: 8),
                                          StatusBadge(status: complaint.status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (complaint.dueDate != null) ...[
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: DateFormatter.isOverdue(complaint.dueDate)
                                                  ? AppColors.error
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormatter.formatDate(complaint.dueDate),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: DateFormatter.isOverdue(complaint.dueDate)
                                                    ? AppColors.error
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                          ],
                                          if (complaint.visitCount > 0) ...[
                                            const Icon(
                                              Icons.event,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${complaint.visitCount} visits',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () => context.push('/home/complaints/${complaint.id}'),
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
