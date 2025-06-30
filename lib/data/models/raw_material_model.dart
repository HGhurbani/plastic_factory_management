// plastic_factory_management/lib/data/models/raw_material_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RawMaterialModel {
  final String id;
  final String code; // كود المادة
  final String name;
  final String unit; // وحدة القياس، مثل 'kg', 'liter', 'piece'
  final Timestamp? lastUpdated;

  RawMaterialModel({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    this.lastUpdated,
  });

  // Constructor from a Firestore DocumentSnapshot
  factory RawMaterialModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RawMaterialModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      unit: data['unit'] ?? '',
      lastUpdated: data['lastUpdated'] as Timestamp?,
    );
  }

  // Convert RawMaterialModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'unit': unit,
      'lastUpdated': lastUpdated,
    };
  }

  // Create a copy with updated values (useful for local state updates before saving)
  RawMaterialModel copyWith({
    String? id,
    String? code,
    String? name,
    String? unit,
    Timestamp? lastUpdated,
  }) {
    return RawMaterialModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}