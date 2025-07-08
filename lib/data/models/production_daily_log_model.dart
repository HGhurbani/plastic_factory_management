// plastic_factory_management/lib/data/models/production_daily_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductionDailyLogModel {
  final String id;
  final String orderId;
  final String supervisorUid;
  final String supervisorName;
  final String? notes;
  final List<String> imageUrls;
  final Timestamp createdAt;

  ProductionDailyLogModel({
    required this.id,
    required this.orderId,
    required this.supervisorUid,
    required this.supervisorName,
    this.notes,
    this.imageUrls = const [],
    required this.createdAt,
  });

  factory ProductionDailyLogModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductionDailyLogModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      supervisorUid: data['supervisorUid'] ?? '',
      supervisorName: data['supervisorName'] ?? '',
      notes: data['notes'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'supervisorUid': supervisorUid,
      'supervisorName': supervisorName,
      'notes': notes,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
    };
  }

  ProductionDailyLogModel copyWith({
    String? id,
    String? orderId,
    String? supervisorUid,
    String? supervisorName,
    String? notes,
    List<String>? imageUrls,
    Timestamp? createdAt,
  }) {
    return ProductionDailyLogModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      supervisorUid: supervisorUid ?? this.supervisorUid,
      supervisorName: supervisorName ?? this.supervisorName,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
