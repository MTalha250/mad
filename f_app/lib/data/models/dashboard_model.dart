import 'project_model.dart';
import 'complaint_model.dart';
import 'invoice_model.dart';
import 'maintenance_model.dart';

class DashboardData {
  final int projectCount;
  final int complaintCount;
  final int maintenanceCount;
  final int invoiceCount;
  final List<Project> recentProjects;
  final List<Complaint> recentComplaints;
  final List<Maintenance> recentMaintenances;
  final List<Invoice> recentInvoices;
  final List<Project> allProjects;
  final List<Complaint> allComplaints;
  final List<Maintenance> allMaintenances;

  DashboardData({
    this.projectCount = 0,
    this.complaintCount = 0,
    this.maintenanceCount = 0,
    this.invoiceCount = 0,
    this.recentProjects = const [],
    this.recentComplaints = const [],
    this.recentMaintenances = const [],
    this.recentInvoices = const [],
    this.allProjects = const [],
    this.allComplaints = const [],
    this.allMaintenances = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      projectCount: json['activeProjects'] ?? json['projectCount'] ?? 0,
      complaintCount: json['activeComplaints'] ?? json['complaintCount'] ?? 0,
      maintenanceCount: json['activeMaintenances'] ?? json['maintenanceCount'] ?? 0,
      invoiceCount: json['activeInvoices'] ?? json['invoiceCount'] ?? 0,
      recentProjects: json['recentProjects'] != null
          ? (json['recentProjects'] as List)
              .map((e) => Project.fromJson(e))
              .toList()
          : [],
      recentComplaints: json['recentComplaints'] != null
          ? (json['recentComplaints'] as List)
              .map((e) => Complaint.fromJson(e))
              .toList()
          : [],
      recentMaintenances: json['recentMaintenances'] != null
          ? (json['recentMaintenances'] as List)
              .map((e) => Maintenance.fromJson(e))
              .toList()
          : [],
      recentInvoices: json['recentInvoices'] != null
          ? (json['recentInvoices'] as List)
              .map((e) => Invoice.fromJson(e))
              .toList()
          : [],
      allProjects: json['allProjects'] != null
          ? (json['allProjects'] as List)
              .map((e) => Project.fromJson(e))
              .toList()
          : [],
      allComplaints: json['allComplaints'] != null
          ? (json['allComplaints'] as List)
              .map((e) => Complaint.fromJson(e))
              .toList()
          : [],
      allMaintenances: json['allMaintenances'] != null
          ? (json['allMaintenances'] as List)
              .map((e) => Maintenance.fromJson(e))
              .toList()
          : [],
    );
  }

  DashboardData copyWith({
    int? projectCount,
    int? complaintCount,
    int? maintenanceCount,
    int? invoiceCount,
    List<Project>? recentProjects,
    List<Complaint>? recentComplaints,
    List<Maintenance>? recentMaintenances,
    List<Invoice>? recentInvoices,
    List<Project>? allProjects,
    List<Complaint>? allComplaints,
    List<Maintenance>? allMaintenances,
  }) {
    return DashboardData(
      projectCount: projectCount ?? this.projectCount,
      complaintCount: complaintCount ?? this.complaintCount,
      maintenanceCount: maintenanceCount ?? this.maintenanceCount,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      recentProjects: recentProjects ?? this.recentProjects,
      recentComplaints: recentComplaints ?? this.recentComplaints,
      recentMaintenances: recentMaintenances ?? this.recentMaintenances,
      recentInvoices: recentInvoices ?? this.recentInvoices,
      allProjects: allProjects ?? this.allProjects,
      allComplaints: allComplaints ?? this.allComplaints,
      allMaintenances: allMaintenances ?? this.allMaintenances,
    );
  }
}

class ChartDataPoint {
  final String month;
  final int projects;
  final int complaints;
  final int maintenances;

  ChartDataPoint({
    required this.month,
    this.projects = 0,
    this.complaints = 0,
    this.maintenances = 0,
  });
}
