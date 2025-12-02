import 'user_model.dart';
import 'value_model.dart';

class ServiceDate {
  final DateTime? serviceDate;
  final DateTime? actualDate;
  final String jcReference;
  final String invoiceRef;
  final String paymentStatus;
  final bool isCompleted;
  final int? month;
  final int? year;

  ServiceDate({
    this.serviceDate,
    this.actualDate,
    this.jcReference = '',
    this.invoiceRef = '',
    this.paymentStatus = 'Pending',
    this.isCompleted = false,
    this.month,
    this.year,
  });

  factory ServiceDate.fromJson(Map<String, dynamic> json) {
    return ServiceDate(
      serviceDate: json['serviceDate'] != null
          ? DateTime.parse(json['serviceDate'])
          : null,
      actualDate: json['actualDate'] != null
          ? DateTime.parse(json['actualDate'])
          : null,
      jcReference: json['jcReference'] ?? '',
      invoiceRef: json['invoiceRef'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      isCompleted: json['isCompleted'] ?? false,
      month: json['month'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    // Compute serviceDate, month, and year - ensuring all are always set
    DateTime computedServiceDate;
    int computedMonth;
    int computedYear;

    if (serviceDate != null) {
      // Use existing serviceDate and derive month/year from it
      computedServiceDate = serviceDate!;
      computedMonth = month ?? serviceDate!.month;
      computedYear = year ?? serviceDate!.year;
    } else if (month != null && year != null) {
      // Compute serviceDate from month/year
      computedServiceDate = DateTime(year!, month!, 1);
      computedMonth = month!;
      computedYear = year!;
    } else {
      // Fallback to current date if nothing is set
      final now = DateTime.now();
      computedServiceDate = DateTime(now.year, now.month, 1);
      computedMonth = now.month;
      computedYear = now.year;
    }

    return {
      'serviceDate': computedServiceDate.toIso8601String(),
      if (actualDate != null) 'actualDate': actualDate!.toIso8601String(),
      'jcReference': jcReference,
      'invoiceRef': invoiceRef,
      'paymentStatus': paymentStatus,
      'isCompleted': isCompleted,
      'month': computedMonth,
      'year': computedYear,
    };
  }

  ServiceDate copyWith({
    DateTime? serviceDate,
    DateTime? actualDate,
    String? jcReference,
    String? invoiceRef,
    String? paymentStatus,
    bool? isCompleted,
    int? month,
    int? year,
  }) {
    return ServiceDate(
      serviceDate: serviceDate ?? this.serviceDate,
      actualDate: actualDate ?? this.actualDate,
      jcReference: jcReference ?? this.jcReference,
      invoiceRef: invoiceRef ?? this.invoiceRef,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isCompleted: isCompleted ?? this.isCompleted,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  bool get isPaid => paymentStatus == 'Paid';
  bool get isPending => paymentStatus == 'Pending';
  bool get isOverdue => paymentStatus == 'Overdue';
}

class Maintenance {
  final String id;
  final String clientName;
  final Value remarks;
  final List<ServiceDate> serviceDates;
  final List<User> users;
  final String status;
  final User? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Maintenance({
    required this.id,
    required this.clientName,
    required this.remarks,
    this.serviceDates = const [],
    this.users = const [],
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    return Maintenance(
      id: json['_id'] ?? '',
      clientName: json['clientName'] ?? '',
      remarks: Value.fromJson(json['remarks']),
      serviceDates: json['serviceDates'] != null
          ? (json['serviceDates'] as List)
              .map((e) => ServiceDate.fromJson(e))
              .toList()
          : [],
      users: json['users'] != null
          ? (json['users'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => User.fromJson(e))
              .toList()
          : [],
      status: json['status'] ?? 'Pending',
      createdBy: json['createdBy'] != null && json['createdBy'] is Map
          ? User.fromJson(json['createdBy'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'clientName': clientName,
      'remarks': remarks.toJson(),
      'serviceDates': serviceDates.map((e) => e.toJson()).toList(),
      'users': users.map((e) => e.id).toList(),
      'status': status,
    };
  }

  Maintenance copyWith({
    String? id,
    String? clientName,
    Value? remarks,
    List<ServiceDate>? serviceDates,
    List<User>? users,
    String? status,
    User? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Maintenance(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      remarks: remarks ?? this.remarks,
      serviceDates: serviceDates ?? this.serviceDates,
      users: users ?? this.users,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get serviceDateCount => serviceDates.length;
  int get completedCount => serviceDates.where((e) => e.isCompleted).length;
  int get pendingCount => serviceDates.where((e) => !e.isCompleted).length;
}

class CreateMaintenanceRequest {
  final String clientName;
  final Value? remarks;
  final List<ServiceDate>? serviceDates;
  final List<String>? users;
  final String? status;

  CreateMaintenanceRequest({
    required this.clientName,
    this.remarks,
    this.serviceDates,
    this.users,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientName': clientName,
      if (remarks != null) 'remarks': remarks!.toJson(),
      if (serviceDates != null)
        'serviceDates': serviceDates!.map((e) => e.toJson()).toList(),
      if (users != null) 'users': users,
      if (status != null) 'status': status,
    };
  }
}
