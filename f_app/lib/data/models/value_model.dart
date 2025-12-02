class Value {
  final String value;
  final bool isEdited;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Value({
    required this.value,
    this.isEdited = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Value.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Value(value: '');
    }
    return Value(
      value: json['value'] ?? '',
      isEdited: json['isEdited'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isEdited': isEdited,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Value copyWith({
    String? value,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Value(
      value: value ?? this.value,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasValue => value.isNotEmpty;

  static Value empty() => Value(value: '');
}
