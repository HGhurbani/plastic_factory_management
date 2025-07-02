// plastic_factory_management/lib/data/models/quality_check_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class QualityCheckModel {
  final String id;
  final String productId;
  final String productName;
  final int inspectedQuantity;
  final int rejectedQuantity;
  final int acceptedQuantity;
  final String shiftSupervisorUid;
  final String shiftSupervisorName;
  final String qualityInspectorUid;
  final String qualityInspectorName;
  final String? defectAnalysis;
  final List<String> imageUrls;
  final Timestamp createdAt;

  QualityCheckModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.inspectedQuantity,
    required this.rejectedQuantity,
    required this.acceptedQuantity,
    required this.shiftSupervisorUid,
    required this.shiftSupervisorName,
    required this.qualityInspectorUid,
    required this.qualityInspectorName,
    this.defectAnalysis,
    this.imageUrls = const [],
    required this.createdAt,
  });

  factory QualityCheckModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QualityCheckModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      inspectedQuantity: data['inspectedQuantity'] ?? 0,
      rejectedQuantity: data['rejectedQuantity'] ?? 0,
      acceptedQuantity: data['acceptedQuantity'] ?? 0,
      shiftSupervisorUid: data['shiftSupervisorUid'] ?? '',
      shiftSupervisorName: data['shiftSupervisorName'] ?? '',
      qualityInspectorUid: data['qualityInspectorUid'] ?? '',
      qualityInspectorName: data['qualityInspectorName'] ?? '',
      defectAnalysis: data['defectAnalysis'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'inspectedQuantity': inspectedQuantity,
      'rejectedQuantity': rejectedQuantity,
      'acceptedQuantity': acceptedQuantity,
      'shiftSupervisorUid': shiftSupervisorUid,
      'shiftSupervisorName': shiftSupervisorName,
      'qualityInspectorUid': qualityInspectorUid,
      'qualityInspectorName': qualityInspectorName,
      'defectAnalysis': defectAnalysis,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
    };
  }

  QualityCheckModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? inspectedQuantity,
    int? rejectedQuantity,
    int? acceptedQuantity,
    String? shiftSupervisorUid,
    String? shiftSupervisorName,
    String? qualityInspectorUid,
    String? qualityInspectorName,
    String? defectAnalysis,
    List<String>? imageUrls,
    Timestamp? createdAt,
  }) {
    return QualityCheckModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      inspectedQuantity: inspectedQuantity ?? this.inspectedQuantity,
      rejectedQuantity: rejectedQuantity ?? this.rejectedQuantity,
      acceptedQuantity: acceptedQuantity ?? this.acceptedQuantity,
      shiftSupervisorUid: shiftSupervisorUid ?? this.shiftSupervisorUid,
      shiftSupervisorName: shiftSupervisorName ?? this.shiftSupervisorName,
      qualityInspectorUid: qualityInspectorUid ?? this.qualityInspectorUid,
      qualityInspectorName: qualityInspectorName ?? this.qualityInspectorName,
      defectAnalysis: defectAnalysis ?? this.defectAnalysis,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
