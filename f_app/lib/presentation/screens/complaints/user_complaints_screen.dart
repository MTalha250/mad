import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/complaint_provider.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/badges/priority_badge.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/inputs/input_field.dart';

class UserComplaintsScreen extends ConsumerStatefulWidget {
  const UserComplaintsScreen({super.key});

  @override
  ConsumerState<UserComplaintsScreen> createState() => _UserComplaintsScreenState();
}

class _UserComplaintsScreenState extends ConsumerState<UserComplaintsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(complaintsProvider.notifier).loadUserComplaints();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(complaintsProvider.notifier).loadUserComplaints();
  }

  @override
  Widget build(BuildContext context) {
    final complaintsState = ref.watch(complaintsProvider);
    final filteredComplaints = complaintsState.filteredComplaints;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
      ),
      body: Column(
        children: [
          // Search
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: InputField(
              controller: _searchController,
              hint: 'Search complaints...',
              prefixIcon: Icons.search,
              onChanged: (value) {
                ref.read(complaintsProvider.notifier).setSearchQuery(value);
              },
            ),
          ),

          // Complaints List
          Expanded(
            child: complaintsState.isLoading && complaintsState.complaints.isEmpty
                ? const LoadingIndicator()
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
                                      'No complaints assigned to you',
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
                                      if (complaint.dueDate != null)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: DateFormatter.isOverdue(complaint.dueDate)
                                                  ? AppColors.error
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Due: ${DateFormatter.formatDate(complaint.dueDate)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: DateFormatter.isOverdue(complaint.dueDate)
                                                    ? AppColors.error
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
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
