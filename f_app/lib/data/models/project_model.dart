import 'user_model.dart';
import 'value_model.dart';

class Project {
  final String id;
  final String clientName;
  final String description;
  final Value po;
  final Value quotation;
  final Value remarks;
  final List<String> surveyPhotos;
  final DateTime? surveyDate;
  final List<Value> jcReferences;
  final List<Value> dcReferences;
  final String status;
  final List<User> users;
  final DateTime? dueDate;
  final User? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Project({
    required this.id,
    required this.clientName,
    this.description = '',
    required this.po,
    required this.quotation,
    required this.remarks,
    this.surveyPhotos = const [],
    this.surveyDate,
    this.jcReferences = const [],
    this.dcReferences = const [],
    required this.status,
    this.users = const [],
    this.dueDate,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['_id'] ?? '',
      clientName: json['clientName'] ?? '',
      description: json['description'] ?? '',
      po: Value.fromJson(json['po']),
      quotation: Value.fromJson(json['quotation']),
      remarks: Value.fromJson(json['remarks']),
      surveyPhotos: json['surveyPhotos'] != null
          ? List<String>.from(json['surveyPhotos'])
          : [],
      surveyDate: json['surveyDate'] != null
          ? DateTime.parse(json['surveyDate'])
          : null,
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
      status: json['status'] ?? 'Pending',
      users: json['users'] != null
          ? (json['users'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => User.fromJson(e))
              .toList()
          : [],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      createdBy: json['createdBy'] != null
          ? (json['createdBy'] is Map ? User.fromJson(json['createdBy']) : null)
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
      'description': description,
      'po': po.toJson(),
      'quotation': quotation.toJson(),
      'remarks': remarks.toJson(),
      'surveyPhotos': surveyPhotos,
      if (surveyDate != null) 'surveyDate': surveyDate!.toIso8601String(),
      'jcReferences': jcReferences.map((e) => e.toJson()).toList(),
      'dcReferences': dcReferences.map((e) => e.toJson()).toList(),
      'status': status,
      'users': users.map((e) => e.id).toList(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
    };
  }

  Project copyWith({
    String? id,
    String? clientName,
    String? description,
    Value? po,
    Value? quotation,
    Value? remarks,
    List<String>? surveyPhotos,
    DateTime? surveyDate,
    List<Value>? jcReferences,
    List<Value>? dcReferences,
    String? status,
    List<User>? users,
    DateTime? dueDate,
    User? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      description: description ?? this.description,
      po: po ?? this.po,
      quotation: quotation ?? this.quotation,
      remarks: remarks ?? this.remarks,
      surveyPhotos: surveyPhotos ?? this.surveyPhotos,
      surveyDate: surveyDate ?? this.surveyDate,
      jcReferences: jcReferences ?? this.jcReferences,
      dcReferences: dcReferences ?? this.dcReferences,
      status: status ?? this.status,
      users: users ?? this.users,
      dueDate: dueDate ?? this.dueDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get jcCount => jcReferences.where((e) => e.hasValue).length;
  int get dcCount => dcReferences.where((e) => e.hasValue).length;
  int get photoCount => surveyPhotos.length;
}

class CreateProjectRequest {
  final String clientName;
  final String description;
  final Value? po;
  final Value? quotation;
  final Value? remarks;
  final DateTime? surveyDate;
  final List<String>? surveyPhotos;
  final List<Value>? jcReferences;
  final List<Value>? dcReferences;
  final String? status;
  final List<String>? users;
  final DateTime? dueDate;

  CreateProjectRequest({
    required this.clientName,
    this.description = '',
    this.po,
    this.quotation,
    this.remarks,
    this.surveyDate,
    this.surveyPhotos,
    this.jcReferences,
    this.dcReferences,
    this.status,
    this.users,
    this.dueDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientName': clientName,
      'description': description,
      if (po != null) 'po': po!.toJson(),
      if (quotation != null) 'quotation': quotation!.toJson(),
      if (remarks != null) 'remarks': remarks!.toJson(),
      if (surveyDate != null) 'surveyDate': surveyDate!.toIso8601String(),
      if (surveyPhotos != null) 'surveyPhotos': surveyPhotos,
      if (jcReferences != null)
        'jcReferences': jcReferences!.map((e) => e.toJson()).toList(),
      if (dcReferences != null)
        'dcReferences': dcReferences!.map((e) => e.toJson()).toList(),
      if (status != null) 'status': status,
      if (users != null) 'users': users,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
    };
  }
}
