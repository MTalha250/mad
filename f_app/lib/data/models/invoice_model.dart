import 'project_model.dart';
import 'user_model.dart';

class Invoice {
  final String id;
  final String invoiceReference;
  final DateTime? invoiceDate;
  final String amount;
  final String paymentTerms;
  final String? creditDays;
  final DateTime? dueDate;
  final Project? project;
  final String? projectId;
  final String status;
  final User? createdBy;
  final String? createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Invoice({
    required this.id,
    this.invoiceReference = '',
    this.invoiceDate,
    required this.amount,
    required this.paymentTerms,
    this.creditDays,
    this.dueDate,
    this.project,
    this.projectId,
    required this.status,
    this.createdBy,
    this.createdById,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['_id'] ?? '',
      invoiceReference: json['invoiceReference'] ?? '',
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'])
          : null,
      amount: json['amount'] ?? '0',
      paymentTerms: json['paymentTerms'] ?? 'Cash',
      creditDays: json['creditDays'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      project: json['project'] != null && json['project'] is Map
          ? Project.fromJson(json['project'])
          : null,
      projectId: json['project'] is String ? json['project'] : null,
      status: json['status'] ?? 'Pending',
      createdBy: json['createdBy'] != null && json['createdBy'] is Map
          ? User.fromJson(json['createdBy'])
          : null,
      createdById: json['createdBy'] is String ? json['createdBy'] : null,
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
      'invoiceReference': invoiceReference,
      if (invoiceDate != null) 'invoiceDate': invoiceDate!.toIso8601String(),
      'amount': amount,
      'paymentTerms': paymentTerms,
      if (creditDays != null) 'creditDays': creditDays,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'project': project?.id ?? projectId,
      'status': status,
    };
  }

  Invoice copyWith({
    String? id,
    String? invoiceReference,
    DateTime? invoiceDate,
    String? amount,
    String? paymentTerms,
    String? creditDays,
    DateTime? dueDate,
    Project? project,
    String? projectId,
    String? status,
    User? createdBy,
    String? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceReference: invoiceReference ?? this.invoiceReference,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      amount: amount ?? this.amount,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      creditDays: creditDays ?? this.creditDays,
      dueDate: dueDate ?? this.dueDate,
      project: project ?? this.project,
      projectId: projectId ?? this.projectId,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCredit => paymentTerms == 'Credit';
  bool get isCash => paymentTerms == 'Cash';

  String get projectClientName => project?.clientName ?? '-';
}

class CreateInvoiceRequest {
  final String invoiceReference;
  final DateTime? invoiceDate;
  final String amount;
  final String paymentTerms;
  final String? creditDays;
  final DateTime? dueDate;
  final String project;
  final String? status;

  CreateInvoiceRequest({
    required this.invoiceReference,
    this.invoiceDate,
    required this.amount,
    required this.paymentTerms,
    this.creditDays,
    this.dueDate,
    required this.project,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceReference': invoiceReference,
      if (invoiceDate != null) 'invoiceDate': invoiceDate!.toIso8601String(),
      'amount': amount,
      'paymentTerms': paymentTerms,
      if (creditDays != null) 'creditDays': creditDays,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'project': project,
      if (status != null) 'status': status,
    };
  }
}
