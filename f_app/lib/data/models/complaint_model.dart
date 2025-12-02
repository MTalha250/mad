import 'user_model.dart';
import 'value_model.dart';

class Complaint {
  final String id;
  final String complaintReference;
  final String clientName;
  final String description;
  final Value po;
  final List<DateTime> visitDates;
  final DateTime? dueDate;
  final User? createdBy;
  final List<User> users;
  final List<Value> jcReferences;
  final List<Value> dcReferences;
  final Value quotation;
  final List<String> photos;
  final String priority;
  final Value remarks;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Complaint({
    required this.id,
    this.complaintReference = '',
    required this.clientName,
    this.description = '',
    required this.po,
    this.visitDates = const [],
    this.dueDate,
    this.createdBy,
    this.users = const [],
    this.jcReferences = const [],
    this.dcReferences = const [],
    required this.quotation,
    this.photos = const [],
    this.priority = 'Medium',
    required this.remarks,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['_id'] ?? '',
      complaintReference: json['complaintReference'] ?? '',
      clientName: json['clientName'] ?? '',
      description: json['description'] ?? '',
      po: Value.fromJson(json['po']),
      visitDates: json['visitDates'] != null
          ? (json['visitDates'] as List)
              .map((e) => DateTime.parse(e))
              .toList()
          : [],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      createdBy: json['createdBy'] != null
          ? (json['createdBy'] is Map ? User.fromJson(json['createdBy']) : null)
          : null,
      users: json['users'] != null
          ? (json['users'] as List).map((e) => User.fromJson(e)).toList()
          : [],
      jcReferences: json['jcReferences'] != null
          ? (json['jcReferences'] as List)
              .map((e) => Value.fromJson(e))
              .toList()
          : [],
      dcReferences: json['dcReferences'] != null
          ? (json['dcReferences'] as List)
              .map((e) => Value.fromJson(e))
              .toList()
          : [],
      quotation: Value.fromJson(json['quotation']),
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      priority: json['priority'] ?? 'Medium',
      remarks: Value.fromJson(json['remarks']),
      status: json['status'] ?? 'Pending',
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
      'complaintReference': complaintReference,
      'clientName': clientName,
      'description': description,
      'po': po.toJson(),
      'visitDates': visitDates.map((e) => e.toIso8601String()).toList(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'users': users.map((e) => e.id).toList(),
      'jcReferences': jcReferences.map((e) => e.toJson()).toList(),
      'dcReferences': dcReferences.map((e) => e.toJson()).toList(),
      'quotation': quotation.toJson(),
      'photos': photos,
      'priority': priority,
      'remarks': remarks.toJson(),
      'status': status,
    };
  }

  Complaint copyWith({
    String? id,
    String? complaintReference,
    String? clientName,
    String? description,
    Value? po,
    List<DateTime>? visitDates,
    DateTime? dueDate,
    User? createdBy,
    List<User>? users,
    List<Value>? jcReferences,
    List<Value>? dcReferences,
    Value? quotation,
    List<String>? photos,
    String? priority,
    Value? remarks,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      complaintReference: complaintReference ?? this.complaintReference,
      clientName: clientName ?? this.clientName,
      description: description ?? this.description,
      po: po ?? this.po,
      visitDates: visitDates ?? this.visitDates,
      dueDate: dueDate ?? this.dueDate,
      createdBy: createdBy ?? this.createdBy,
      users: users ?? this.users,
      jcReferences: jcReferences ?? this.jcReferences,
      dcReferences: dcReferences ?? this.dcReferences,
      quotation: quotation ?? this.quotation,
      photos: photos ?? this.photos,
      priority: priority ?? this.priority,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get jcCount => jcReferences.where((e) => e.hasValue).length;
  int get dcCount => dcReferences.where((e) => e.hasValue).length;
  int get visitCount => visitDates.length;
  int get photoCount => photos.length;
}

class CreateComplaintRequest {
  final String? complaintReference;
  final String clientName;
  final String description;
  final Value? po;
  final List<DateTime>? visitDates;
  final DateTime? dueDate;
  final List<String>? users;
  final List<Value>? jcReferences;
  final List<Value>? dcReferences;
  final Value? quotation;
  final List<String>? photos;
  final String? priority;
  final Value? remarks;
  final String? status;

  CreateComplaintRequest({
    this.complaintReference,
    required this.clientName,
    this.description = '',
    this.po,
    this.visitDates,
    this.dueDate,
    this.users,
    this.jcReferences,
    this.dcReferences,
    this.quotation,
    this.photos,
    this.priority,
    this.remarks,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      if (complaintReference != null) 'complaintReference': complaintReference,
      'clientName': clientName,
      'description': description,
      if (po != null) 'po': po!.toJson(),
      if (visitDates != null)
        'visitDates': visitDates!.map((e) => e.toIso8601String()).toList(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (users != null) 'users': users,
      if (jcReferences != null)
        'jcReferences': jcReferences!.map((e) => e.toJson()).toList(),
      if (dcReferences != null)
        'dcReferences': dcReferences!.map((e) => e.toJson()).toList(),
      if (quotation != null) 'quotation': quotation!.toJson(),
      if (photos != null) 'photos': photos,
      if (priority != null) 'priority': priority,
      if (remarks != null) 'remarks': remarks!.toJson(),
      if (status != null) 'status': status,
    };
  }
}
