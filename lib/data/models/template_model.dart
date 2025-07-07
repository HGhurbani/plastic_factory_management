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
  final double weight; // الوزن
  final double costPerHour; // تكلفة الساعة للقالب
  final List<TemplateMaterial> materialsUsed; // المواد المستخدمة
  final List<String> colors; // الألوان
  final List<String> productionInputs; // مدخلات الإنتاج

  TemplateModel({
    required this.id,
    required this.code,
    required this.name,
    required this.weight,
    required this.costPerHour,
    required this.materialsUsed,
    required this.colors,
    required this.productionInputs,
  });

  factory TemplateModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TemplateModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      costPerHour: (data['costPerHour'] as num?)?.toDouble() ?? 0.0,
      materialsUsed: (data['materialsUsed'] as List<dynamic>?)
              ?.map((e) => TemplateMaterial.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      colors: List<String>.from(data['colors'] ?? []),
      productionInputs: List<String>.from(data['productionInputs'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'weight': weight,
      'costPerHour': costPerHour,
      'materialsUsed': materialsUsed.map((e) => e.toMap()).toList(),
      'colors': colors,
      'productionInputs': productionInputs,
    };
  }

  TemplateModel copyWith({
    String? id,
    String? code,
    String? name,
    double? weight,
    double? costPerHour,
    List<TemplateMaterial>? materialsUsed,
    List<String>? colors,
    List<String>? productionInputs,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      costPerHour: costPerHour ?? this.costPerHour,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      colors: colors ?? this.colors,
      productionInputs: productionInputs ?? this.productionInputs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
