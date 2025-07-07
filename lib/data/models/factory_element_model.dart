import 'package:cloud_firestore/cloud_firestore.dart';

class FactoryElementModel {
  final String id;
  final String type;
  final String name;

  FactoryElementModel({
    required this.id,
    required this.type,
    required this.name,
  });

  factory FactoryElementModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FactoryElementModel(
      id: doc.id,
      type: data['type'] ?? '',
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
    };
  }

  FactoryElementModel copyWith({String? id, String? type, String? name}) {
    return FactoryElementModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
    );
  }
}
