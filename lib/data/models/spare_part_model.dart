import 'package:cloud_firestore/cloud_firestore.dart';

class SparePartModel {
  final String id;
  final String code;
  final String name;
  final String unit;
  final Timestamp? lastUpdated;

  SparePartModel({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    this.lastUpdated,
  });

  factory SparePartModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SparePartModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      unit: data['unit'] ?? '',
      lastUpdated: data['lastUpdated'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'unit': unit,
      'lastUpdated': lastUpdated,
    };
  }

  SparePartModel copyWith({
    String? id,
    String? code,
    String? name,
    String? unit,
    Timestamp? lastUpdated,
  }) {
    return SparePartModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SparePartModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
