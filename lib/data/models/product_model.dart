// plastic_factory_management/lib/data/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// يمثل مادة واحدة وكميتها ضمن قائمة المواد (Bill of Materials) لمنتج معين
class ProductMaterial {
  final String materialId; // مرجع لـ RawMaterialModel
  final double quantityPerUnit; // الكمية المطلوبة من هذه المادة لإنتاج وحدة واحدة من المنتج
  final String unit; // وحدة القياس الخاصة بهذه المادة في هذا المنتج (مثال: 'kg', 'liter')

  ProductMaterial({
    required this.materialId,
    required this.quantityPerUnit,
    required this.unit,
  });

  factory ProductMaterial.fromMap(Map<String, dynamic> map) {
    return ProductMaterial(
      materialId: map['materialId'] ?? '',
      quantityPerUnit: (map['quantityPerUnit'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'quantityPerUnit': quantityPerUnit,
      'unit': unit,
    };
  }
}

class ProductModel {
  final String id;
  final String productCode;
  final String name;
  final String? description;
  final String? imageUrl; // رابط لصورة المنتج في Firebase Storage
  final List<ProductMaterial> billOfMaterials; // المواد المستخدمة لإنتاجه مع الكميات
  final List<String> colors; // الألوان المتاحة للمنتج
  final List<String> additives; // الإضافات المطلوبة (مثل مثبتات UV)
  final String packagingType; // نوع التعبئة (مثال: 'صندوق', 'تغليف حراري')
  final bool requiresPackaging; // هل يحتاج المنتج لتعبئة؟
  final bool requiresSticker; // هل يحتاج المنتج لستيكر؟
  final String productType; // 'compound' (مركب من عدة أجزاء) or 'single' (فردي)
  final double expectedProductionTimePerUnit; // الوقت المتوقع لإنتاج وحدة واحدة (بالدقائق)

  ProductModel({
    required this.id,
    required this.productCode,
    required this.name,
    this.description,
    this.imageUrl,
    required this.billOfMaterials,
    required this.colors,
    required this.additives,
    required this.packagingType,
    required this.requiresPackaging,
    required this.requiresSticker,
    required this.productType,
    required this.expectedProductionTimePerUnit,
  });

  // Constructor from a Firestore DocumentSnapshot
  factory ProductModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      productCode: data['productCode'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      billOfMaterials: (data['billOfMaterials'] as List<dynamic>?)
          ?.map((item) => ProductMaterial.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      colors: List<String>.from(data['colors'] ?? []),
      additives: List<String>.from(data['additives'] ?? []),
      packagingType: data['packagingType'] ?? '',
      requiresPackaging: data['requiresPackaging'] ?? false,
      requiresSticker: data['requiresSticker'] ?? false,
      productType: data['productType'] ?? 'single',
      expectedProductionTimePerUnit: (data['expectedProductionTimePerUnit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Convert ProductModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'productCode': productCode,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'billOfMaterials': billOfMaterials.map((e) => e.toMap()).toList(),
      'colors': colors,
      'additives': additives,
      'packagingType': packagingType,
      'requiresPackaging': requiresPackaging,
      'requiresSticker': requiresSticker,
      'productType': productType,
      'expectedProductionTimePerUnit': expectedProductionTimePerUnit,
    };
  }

  // Create a copy with updated values
  ProductModel copyWith({
    String? id,
    String? productCode,
    String? name,
    String? description,
    String? imageUrl,
    List<ProductMaterial>? billOfMaterials,
    List<String>? colors,
    List<String>? additives,
    String? packagingType,
    bool? requiresPackaging,
    bool? requiresSticker,
    String? productType,
    double? expectedProductionTimePerUnit,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productCode: productCode ?? this.productCode,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      billOfMaterials: billOfMaterials ?? this.billOfMaterials,
      colors: colors ?? this.colors,
      additives: additives ?? this.additives,
      packagingType: packagingType ?? this.packagingType,
      requiresPackaging: requiresPackaging ?? this.requiresPackaging,
      requiresSticker: requiresSticker ?? this.requiresSticker,
      productType: productType ?? this.productType,
      expectedProductionTimePerUnit: expectedProductionTimePerUnit ?? this.expectedProductionTimePerUnit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}