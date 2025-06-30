// plastic_factory_management/lib/data/models/template_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateMaterial {
  final String materialId; // مرجع للمادة
  final double ratio; // النسبة أو الكمية

  TemplateMaterial({required this.materialId, required this.ratio});

  factory TemplateMaterial.fromMap(Map<String, dynamic> map) {
    return TemplateMaterial(
      materialId: map['materialId'] ?? '',
      ratio: (map['ratio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'ratio': ratio,
    };
  }
}

class TemplateModel {
  final String id; // Firestore document ID
  final String code; // الكود
  final String name; // الاسم
  final double timeRequired; // الوقت المستغرق بالدقائق
  final List<TemplateMaterial> materialsUsed; // المواد المستخدمة
  final List<String> colors; // الألوان
  final double percentage; // النسبة
  final List<String> additives; // الإضافات

  TemplateModel({
    required this.id,
    required this.code,
    required this.name,
    required this.timeRequired,
    required this.materialsUsed,
    required this.colors,
    required this.percentage,
    required this.additives,
  });

  factory TemplateModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TemplateModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      timeRequired: (data['timeRequired'] as num?)?.toDouble() ?? 0.0,
      materialsUsed: (data['materialsUsed'] as List<dynamic>?)
              ?.map((e) => TemplateMaterial.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      colors: List<String>.from(data['colors'] ?? []),
      percentage: (data['percentage'] as num?)?.toDouble() ?? 0.0,
      additives: List<String>.from(data['additives'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'timeRequired': timeRequired,
      'materialsUsed': materialsUsed.map((e) => e.toMap()).toList(),
      'colors': colors,
      'percentage': percentage,
      'additives': additives,
    };
  }

  TemplateModel copyWith({
    String? id,
    String? code,
    String? name,
    double? timeRequired,
    List<TemplateMaterial>? materialsUsed,
    List<String>? colors,
    double? percentage,
    List<String>? additives,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      timeRequired: timeRequired ?? this.timeRequired,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      colors: colors ?? this.colors,
      percentage: percentage ?? this.percentage,
      additives: additives ?? this.additives,
    );
  }
}
