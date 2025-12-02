import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/project_provider.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/inputs/input_field.dart';

class UserProjectsScreen extends ConsumerStatefulWidget {
  const UserProjectsScreen({super.key});

  @override
  ConsumerState<UserProjectsScreen> createState() => _UserProjectsScreenState();
}

class _UserProjectsScreenState extends ConsumerState<UserProjectsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(projectsProvider.notifier).loadUserProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(projectsProvider.notifier).loadUserProjects();
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);
    final filteredProjects = projectsState.filteredProjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
      ),
      body: Column(
        children: [
          // Search
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: InputField(
              controller: _searchController,
              hint: 'Search projects...',
              prefixIcon: Icons.search,
              onChanged: (value) {
                ref.read(projectsProvider.notifier).setSearchQuery(value);
              },
            ),
          ),

          // Projects List
          Expanded(
            child: projectsState.isLoading && projectsState.projects.isEmpty
                ? const LoadingIndicator()
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.primary,
                    child: filteredProjects.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.folder_off_outlined,
                                      size: 64,
                                      color: AppColors.textTertiary,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No projects assigned to you',
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
                            itemCount: filteredProjects.length,
                            itemBuilder: (context, index) {
                              final project = filteredProjects[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    project.clientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (project.description.isNotEmpty)
                                        Text(
                                          project.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      if (project.dueDate != null)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: DateFormatter.isOverdue(project.dueDate)
                                                  ? AppColors.error
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Due: ${DateFormatter.formatDate(project.dueDate)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: DateFormatter.isOverdue(project.dueDate)
                                                    ? AppColors.error
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  trailing: StatusBadge(status: project.status),
                                  onTap: () => context.push('/home/projects/${project.id}'),
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
