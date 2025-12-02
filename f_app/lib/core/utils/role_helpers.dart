class RoleHelpers {
  // Check if user has admin-level access
  static bool isAdmin(String? role) {
    return role == 'director' || role == 'admin';
  }

  // Check if user has head-level access
  static bool isHead(String? role) {
    return role == 'director' || role == 'admin' || role == 'head';
  }

  // Check if user is a regular user
  static bool isUser(String? role) {
    return role == 'user';
  }

  // Check if user is director
  static bool isDirector(String? role) {
    return role == 'director';
  }

  // Check if user can view projects based on role and department
  static bool canViewProjects(String? role, String? department) {
    if (isAdmin(role)) return true;
    if (role == 'head') {
      return ['technical', 'it', 'store'].contains(department);
    }
    return role == 'user';
  }

  // Check if user can view complaints based on role and department
  static bool canViewComplaints(String? role, String? department) {
    if (isAdmin(role)) return true;
    if (role == 'head') {
      return ['technical', 'it', 'store'].contains(department);
    }
    return role == 'user';
  }

  // Check if user can view maintenances based on role and department
  static bool canViewMaintenances(String? role, String? department) {
    if (isAdmin(role)) return true;
    if (role == 'head') {
      return ['technical', 'it'].contains(department);
    }
    return role == 'user';
  }

  // Check if user can view invoices based on role and department
  static bool canViewInvoices(String? role, String? department) {
    if (isAdmin(role)) return true;
    if (role == 'head') {
      return ['accounts', 'sales'].contains(department);
    }
    return false;
  }

  // Check if user can view approvals
  static bool canViewApprovals(String? role) {
    return isAdmin(role);
  }

  // Check if user can create/edit items
  static bool canCreate(String? role) {
    return isHead(role);
  }

  // Check if user can delete items
  static bool canDelete(String? role) {
    return isAdmin(role);
  }

  // Check if user can approve/reject users
  static bool canApproveUsers(String? role) {
    return isAdmin(role);
  }

  // Check if user can assign users to items
  static bool canAssignUsers(String? role) {
    return isHead(role);
  }

  // Get display name for role
  static String getRoleDisplayName(String? role) {
    switch (role) {
      case 'director':
        return 'Director';
      case 'admin':
        return 'Admin';
      case 'head':
        return 'Head';
      case 'user':
        return 'User';
      default:
        return role ?? 'Unknown';
    }
  }

  // Get display name for department
  static String getDepartmentDisplayName(String? department) {
    switch (department) {
      case 'accounts':
        return 'Accounts';
      case 'technical':
        return 'Technical';
      case 'it':
        return 'IT';
      case 'sales':
        return 'Sales';
      case 'store':
        return 'Store';
      default:
        return department ?? '-';
    }
  }

  // Get list of roles for dropdown
  static List<Map<String, String>> getRoleOptions() {
    return [
      {'value': 'director', 'label': 'Director'},
      {'value': 'admin', 'label': 'Admin'},
      {'value': 'head', 'label': 'Head'},
      {'value': 'user', 'label': 'User'},
    ];
  }

  // Get list of departments for dropdown
  static List<Map<String, String>> getDepartmentOptions() {
    return [
      {'value': 'accounts', 'label': 'Accounts'},
      {'value': 'technical', 'label': 'Technical'},
      {'value': 'it', 'label': 'IT'},
      {'value': 'sales', 'label': 'Sales'},
      {'value': 'store', 'label': 'Store'},
    ];
  }
}
