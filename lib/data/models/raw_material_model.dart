// plastic_factory_management/lib/data/models/raw_material_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RawMaterialModel {
  final String id;
  final String name;
  final double currentQuantity;
  final String unit; // وحدة القياس، مثل 'kg', 'liter', 'piece'
  final double minStockLevel; // الحد الأدنى للمخزون (للتنبيهات)
  final Timestamp lastUpdated;

  RawMaterialModel({
    required this.id,
    required this.name,
    required this.currentQuantity,
    required this.unit,
    required this.minStockLevel,
    required this.lastUpdated,
  });

  // Constructor from a Firestore DocumentSnapshot
  factory RawMaterialModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RawMaterialModel(
      id: doc.id,
      name: data['name'] ?? '',
      currentQuantity: (data['currentQuantity'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? '',
      minStockLevel: (data['minStockLevel'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
    );
  }

  // Convert RawMaterialModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'currentQuantity': currentQuantity,
      'unit': unit,
      'minStockLevel': minStockLevel,
      'lastUpdated': lastUpdated,
    };
  }

  // Create a copy with updated values (useful for local state updates before saving)
  RawMaterialModel copyWith({
    String? id,
    String? name,
    double? currentQuantity,
    String? unit,
    double? minStockLevel,
    Timestamp? lastUpdated,
  }) {
    return RawMaterialModel(
      id: id ?? this.id,
      name: name ?? this.name,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      unit: unit ?? this.unit,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}