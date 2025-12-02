class ApiEndpoints {
  // Auth
  static const String login = '/users/login';
  static const String register = '/users/register';
  static const String forgotPassword = '/users/forgot-password';
  static const String verifyResetCode = '/users/verify-reset-code';
  static const String resetPassword = '/users/reset-password';
  static const String updatePushToken = '/users/update-push-token';

  // User Profile
  static const String profile = '/users/profile';

  // Users (Admin)
  static const String users = '/users';
  static const String pendingUsers = '/users/pending';
  static const String approvedUsers = '/users/approved';
  static String pendingUserById(String id) => '/users/pending/$id';
  static String userById(String id) => '/users/$id';

  // Projects
  static const String projects = '/projects';
  static const String userProjects = '/projects/user';
  static String projectById(String id) => '/projects/$id';
  static String projectsByStatus(String status) => '/projects/status/$status';
  static String assignProjectUsers(String id) => '/projects/$id/assign-users';

  // Complaints
  static const String complaints = '/complaints';
  static const String userComplaints = '/complaints/user';
  static String complaintById(String id) => '/complaints/$id';
  static String complaintsByStatus(String status) => '/complaints/status/$status';
  static String complaintsByPriority(String priority) => '/complaints/priority/$priority';
  static String assignComplaintUsers(String id) => '/complaints/$id/assign-users';

  // Invoices
  static const String invoices = '/invoices';
  static const String overdueInvoices = '/invoices/overdue';
  static String invoiceById(String id) => '/invoices/$id';
  static String invoicesByStatus(String status) => '/invoices/status/$status';
  static String invoicesByPaymentTerms(String terms) => '/invoices/payment-terms/$terms';
  static String invoicesByProject(String projectId) => '/invoices/project/$projectId';

  // Maintenances
  static const String maintenances = '/maintenances';
  static const String userMaintenances = '/maintenances/user';
  static const String upcomingMaintenances = '/maintenances/upcoming';
  static String maintenanceById(String id) => '/maintenances/$id';
  static String maintenancesByStatus(String status) => '/maintenances/status/$status';
  static String assignMaintenanceUsers(String id) => '/maintenances/$id/assign-users';

  // Dashboard
  static const String dashboard = '/dashboard';
  static const String userDashboard = '/dashboard/user';
}
