import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';

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
  final String? itemId;
  final String? itemName;
  final InventoryItemType? itemType;
  final double? quantity;

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
    this.itemId,
    this.itemName,
    this.itemType,
    this.quantity,
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
      itemId: data['itemId'],
      itemName: data['itemName'],
      itemType: data['itemType'] != null
          ? inventoryItemTypeFromString(data['itemType'])
          : null,
      quantity: (data['quantity'] as num?)?.toDouble(),
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
      if (itemId != null) 'itemId': itemId,
      if (itemName != null) 'itemName': itemName,
      if (itemType != null) 'itemType': inventoryItemTypeToString(itemType!),
      if (quantity != null) 'quantity': quantity,
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
    String? itemId,
    String? itemName,
    InventoryItemType? itemType,
    double? quantity,
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
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
    );
  }
}
