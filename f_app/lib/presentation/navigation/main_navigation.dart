import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../core/utils/role_helpers.dart';
import '../../providers/auth_provider.dart';
import 'app_router.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final Widget child;

  const MainNavigation({super.key, required this.child});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final role = ref.read(userRoleProvider);
    final department = ref.read(userDepartmentProvider);
    final tabs = _getTabsForRole(role, department);

    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].route)) {
        return i;
      }
    }
    return 0;
  }

  List<_TabItem> _getTabsForRole(String? role, String? department) {
    final tabs = <_TabItem>[];

    // Dashboard - always shown
    if (role == 'user') {
      tabs.add(_TabItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        route: AppRoutes.userDashboard,
      ));
    } else {
      tabs.add(_TabItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        route: AppRoutes.dashboard,
      ));
    }

    // Projects
    if (RoleHelpers.canViewProjects(role, department)) {
      if (role == 'user') {
        tabs.add(_TabItem(
          icon: Icons.folder_outlined,
          selectedIcon: Icons.folder,
          label: 'Projects',
          route: AppRoutes.userProjects,
        ));
      } else {
        tabs.add(_TabItem(
          icon: Icons.folder_outlined,
          selectedIcon: Icons.folder,
          label: 'Projects',
          route: AppRoutes.projects,
        ));
      }
    }

    // Complaints
    if (RoleHelpers.canViewComplaints(role, department)) {
      if (role == 'user') {
        tabs.add(_TabItem(
          icon: Icons.report_problem_outlined,
          selectedIcon: Icons.report_problem,
          label: 'Complaints',
          route: AppRoutes.userComplaints,
        ));
      } else {
        tabs.add(_TabItem(
          icon: Icons.report_problem_outlined,
          selectedIcon: Icons.report_problem,
          label: 'Complaints',
          route: AppRoutes.complaints,
        ));
      }
    }

    // Maintenances
    if (RoleHelpers.canViewMaintenances(role, department)) {
      if (role == 'user') {
        tabs.add(_TabItem(
          icon: Icons.build_outlined,
          selectedIcon: Icons.build,
          label: 'Maintenance',
          route: AppRoutes.userMaintenances,
        ));
      } else {
        tabs.add(_TabItem(
          icon: Icons.build_outlined,
          selectedIcon: Icons.build,
          label: 'Maintenance',
          route: AppRoutes.maintenances,
        ));
      }
    }

    // Invoices
    if (RoleHelpers.canViewInvoices(role, department)) {
      tabs.add(_TabItem(
        icon: Icons.receipt_outlined,
        selectedIcon: Icons.receipt,
        label: 'Invoices',
        route: AppRoutes.invoices,
      ));
    }

    // Approvals
    if (RoleHelpers.canViewApprovals(role)) {
      tabs.add(_TabItem(
        icon: Icons.how_to_reg_outlined,
        selectedIcon: Icons.how_to_reg,
        label: 'Approvals',
        route: AppRoutes.approvals,
      ));
    }

    return tabs;
  }

  void _onItemTapped(int index, List<_TabItem> tabs) {
    context.go(tabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final department = ref.watch(userDepartmentProvider);
    final tabs = _getTabsForRole(role, department);
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => _onItemTapped(index, tabs),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Icon(
                      isSelected ? tab.selectedIcon : tab.icon,
                      size: 24,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}
