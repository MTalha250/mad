import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/admin_dashboard_screen.dart';
import '../screens/dashboard/user_dashboard_screen.dart';
import '../screens/projects/projects_list_screen.dart';
import '../screens/projects/project_detail_screen.dart';
import '../screens/projects/create_project_screen.dart';
import '../screens/projects/user_projects_screen.dart';
import '../screens/complaints/complaints_list_screen.dart';
import '../screens/complaints/complaint_detail_screen.dart';
import '../screens/complaints/create_complaint_screen.dart';
import '../screens/complaints/user_complaints_screen.dart';
import '../screens/maintenances/maintenances_list_screen.dart';
import '../screens/maintenances/maintenance_detail_screen.dart';
import '../screens/maintenances/create_maintenance_screen.dart';
import '../screens/maintenances/user_maintenances_screen.dart';
import '../screens/invoices/invoices_list_screen.dart';
import '../screens/invoices/invoice_detail_screen.dart';
import '../screens/invoices/create_invoice_screen.dart';
import '../screens/approvals/approvals_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'main_navigation.dart';

// Route names
class AppRoutes {
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String dashboard = '/home/dashboard';
  static const String userDashboard = '/home/user-dashboard';
  static const String projects = '/home/projects';
  static const String userProjects = '/home/user-projects';
  static const String projectDetail = '/home/projects/:id';
  static const String createProject = '/home/projects/create';
  static const String complaints = '/home/complaints';
  static const String userComplaints = '/home/user-complaints';
  static const String complaintDetail = '/home/complaints/:id';
  static const String createComplaint = '/home/complaints/create';
  static const String maintenances = '/home/maintenances';
  static const String userMaintenances = '/home/user-maintenances';
  static const String maintenanceDetail = '/home/maintenances/:id';
  static const String createMaintenance = '/home/maintenances/create';
  static const String invoices = '/home/invoices';
  static const String invoiceDetail = '/home/invoices/:id';
  static const String createInvoice = '/home/invoices/create';
  static const String approvals = '/home/approvals';
  static const String profile = '/home/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isAuthRoute = state.matchedLocation == AppRoutes.signIn ||
          state.matchedLocation == AppRoutes.signUp ||
          state.matchedLocation == AppRoutes.forgotPassword;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      // If already authenticated, don't redirect anywhere during loading
      // This prevents logout during profile updates or other operations
      if (isAuthenticated) {
        // Just redirect away from auth routes and splash
        if (isAuthRoute || isSplash) {
          return AppRoutes.home;
        }
        return null;
      }

      // Not authenticated - check if still loading initial auth
      if (isLoading && isSplash) {
        return null; // Stay on splash while checking auth
      }

      // Not authenticated and not loading - go to sign in
      if (!isAuthRoute) {
        return AppRoutes.signIn;
      }

      return null;
    },
    routes: [
      // Splash/Loading screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            redirect: (context, state) {
              if (state.matchedLocation == AppRoutes.home) {
                final role = authState.role;
                if (role == 'user') {
                  return AppRoutes.userDashboard;
                }
                return AppRoutes.dashboard;
              }
              return null;
            },
            builder: (context, state) => const SizedBox.shrink(),
          ),
          // Dashboards
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.userDashboard,
            builder: (context, state) => const UserDashboardScreen(),
          ),

          // Projects
          GoRoute(
            path: AppRoutes.projects,
            builder: (context, state) => const ProjectsListScreen(),
          ),
          GoRoute(
            path: AppRoutes.userProjects,
            builder: (context, state) => const UserProjectsScreen(),
          ),
          GoRoute(
            path: AppRoutes.createProject,
            builder: (context, state) => const CreateProjectScreen(),
          ),
          GoRoute(
            path: AppRoutes.projectDetail,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProjectDetailScreen(projectId: id);
            },
          ),

          // Complaints
          GoRoute(
            path: AppRoutes.complaints,
            builder: (context, state) => const ComplaintsListScreen(),
          ),
          GoRoute(
            path: AppRoutes.userComplaints,
            builder: (context, state) => const UserComplaintsScreen(),
          ),
          GoRoute(
            path: AppRoutes.createComplaint,
            builder: (context, state) => const CreateComplaintScreen(),
          ),
          GoRoute(
            path: AppRoutes.complaintDetail,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ComplaintDetailScreen(complaintId: id);
            },
          ),

          // Maintenances
          GoRoute(
            path: AppRoutes.maintenances,
            builder: (context, state) => const MaintenancesListScreen(),
          ),
          GoRoute(
            path: AppRoutes.userMaintenances,
            builder: (context, state) => const UserMaintenancesScreen(),
          ),
          GoRoute(
            path: AppRoutes.createMaintenance,
            builder: (context, state) => const CreateMaintenanceScreen(),
          ),
          GoRoute(
            path: AppRoutes.maintenanceDetail,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaintenanceDetailScreen(maintenanceId: id);
            },
          ),

          // Invoices
          GoRoute(
            path: AppRoutes.invoices,
            builder: (context, state) => const InvoicesListScreen(),
          ),
          GoRoute(
            path: AppRoutes.createInvoice,
            builder: (context, state) => const CreateInvoiceScreen(),
          ),
          GoRoute(
            path: AppRoutes.invoiceDetail,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InvoiceDetailScreen(invoiceId: id);
            },
          ),

          // Approvals
          GoRoute(
            path: AppRoutes.approvals,
            builder: (context, state) => const ApprovalsScreen(),
          ),

          // Profile
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

// Splash screen for initial loading
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkAuth());
  }

  Future<void> _checkAuth() async {
    await ref.read(authProvider.notifier).checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE9F8FF)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_center,
                size: 80,
                color: Color(0xFFA82F39),
              ),
              SizedBox(height: 24),
              Text(
                'TechnoTrends',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA82F39),
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                color: Color(0xFFA82F39),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
