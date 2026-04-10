class Promotion {
  final String id;
  final String title;
  final String description;
  final String code;
  final double discountPercent;
  final int maxUses;
  final int currentUses;
  final String validFrom;
  final String validUntil;
  final String targetGroup;
  final bool active;

  const Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.discountPercent,
    required this.maxUses,
    required this.currentUses,
    required this.validFrom,
    required this.validUntil,
    required this.targetGroup,
    required this.active,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      code: json['code'] ?? '',
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      maxUses: json['maxUses'] ?? 0,
      currentUses: json['currentUses'] ?? 0,
      validFrom: json['validFrom'] ?? '',
      validUntil: json['validUntil'] ?? '',
      targetGroup: json['targetGroup'] ?? 'all',
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'code': code,
        'discountPercent': discountPercent,
        'maxUses': maxUses,
        'currentUses': currentUses,
        'validFrom': validFrom,
        'validUntil': validUntil,
        'targetGroup': targetGroup,
        'active': active,
      };

  Promotion copyWith({
    String? id,
    String? title,
    String? description,
    String? code,
    double? discountPercent,
    int? maxUses,
    int? currentUses,
    String? validFrom,
    String? validUntil,
    String? targetGroup,
    bool? active,
  }) {
    return Promotion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      code: code ?? this.code,
      discountPercent: discountPercent ?? this.discountPercent,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      targetGroup: targetGroup ?? this.targetGroup,
      active: active ?? this.active,
    );
  }
}
