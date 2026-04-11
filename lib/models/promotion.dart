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

  Promotion copyWith([PromotionChanges changes = const PromotionChanges()]) {
    return Promotion(
      id: changes.id ?? id,
      title: changes.title ?? title,
      description: changes.description ?? description,
      code: changes.code ?? code,
      discountPercent: changes.discountPercent ?? discountPercent,
      maxUses: changes.maxUses ?? maxUses,
      currentUses: changes.currentUses ?? currentUses,
      validFrom: changes.validFrom ?? validFrom,
      validUntil: changes.validUntil ?? validUntil,
      targetGroup: changes.targetGroup ?? targetGroup,
      active: changes.active ?? active,
    );
  }
}

class PromotionChanges {
  final String? id;
  final String? title;
  final String? description;
  final String? code;
  final double? discountPercent;
  final int? maxUses;
  final int? currentUses;
  final String? validFrom;
  final String? validUntil;
  final String? targetGroup;
  final bool? active;

  const PromotionChanges({
    this.id,
    this.title,
    this.description,
    this.code,
    this.discountPercent,
    this.maxUses,
    this.currentUses,
    this.validFrom,
    this.validUntil,
    this.targetGroup,
    this.active,
  });
}
