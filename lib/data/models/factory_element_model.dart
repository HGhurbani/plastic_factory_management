import 'package:cloud_firestore/cloud_firestore.dart';

class FactoryElementModel {
  final String id;
  final String type;
  final String name;
  final String? unit; // Optional unit for raw materials

  FactoryElementModel({
    required this.id,
    required this.type,
    required this.name,
    this.unit,
  });

  factory FactoryElementModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FactoryElementModel(
      id: doc.id,
      type: data['type'] ?? '',
      name: data['name'] ?? '',
      unit: data['unit'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      if (unit != null) 'unit': unit,
    };
  }

  FactoryElementModel copyWith({String? id, String? type, String? name, String? unit}) {
    return FactoryElementModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      unit: unit ?? this.unit,
    );
  }
}
