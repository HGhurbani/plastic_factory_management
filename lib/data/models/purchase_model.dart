import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  final String id;
  final String description;
  final String category; // مثلا "قطع غيار" أو "مواد خام"
  final double amount;
  final Timestamp purchaseDate;
  final String? maintenanceLogId;
  final String? productionOrderId;
  final String createdByUid;
  final String createdByName;

  PurchaseModel({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.purchaseDate,
    this.maintenanceLogId,
    this.productionOrderId,
    required this.createdByUid,
    required this.createdByName,
  });

  factory PurchaseModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseModel(
      id: doc.id,
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: data['purchaseDate'] ?? Timestamp.now(),
      maintenanceLogId: data['maintenanceLogId'],
      productionOrderId: data['productionOrderId'],
      createdByUid: data['createdByUid'] ?? '',
      createdByName: data['createdByName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'category': category,
      'amount': amount,
      'purchaseDate': purchaseDate,
      'maintenanceLogId': maintenanceLogId,
      'productionOrderId': productionOrderId,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
    };
  }

  PurchaseModel copyWith({
    String? id,
    String? description,
    String? category,
    double? amount,
    Timestamp? purchaseDate,
    String? maintenanceLogId,
    String? productionOrderId,
    String? createdByUid,
    String? createdByName,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      description: description ?? this.description,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      maintenanceLogId: maintenanceLogId ?? this.maintenanceLogId,
      productionOrderId: productionOrderId ?? this.productionOrderId,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}
