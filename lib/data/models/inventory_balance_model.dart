import 'package:cloud_firestore/cloud_firestore.dart';

enum InventoryItemType { rawMaterial, finishedProduct, sparePart }

InventoryItemType inventoryItemTypeFromString(String type) {
  switch (type) {
    case 'raw':
      return InventoryItemType.rawMaterial;
    case 'product':
      return InventoryItemType.finishedProduct;
    case 'spare':
      return InventoryItemType.sparePart;
    default:
      return InventoryItemType.rawMaterial;
  }
}

String inventoryItemTypeToString(InventoryItemType type) {
  switch (type) {
    case InventoryItemType.rawMaterial:
      return 'raw';
    case InventoryItemType.finishedProduct:
      return 'product';
    case InventoryItemType.sparePart:
      return 'spare';
  }
}

class InventoryBalanceModel {
  final String id;
  final String itemId;
  final InventoryItemType type;
  final double quantity;
  final double minQuantity;
  final Timestamp? lastUpdated;

  InventoryBalanceModel({
    required this.id,
    required this.itemId,
    required this.type,
    required this.quantity,
    required this.minQuantity,
    this.lastUpdated,
  });

  factory InventoryBalanceModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryBalanceModel(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      type: inventoryItemTypeFromString(data['type'] ?? 'raw'),
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0,
      minQuantity: (data['minQuantity'] as num?)?.toDouble() ?? 0,
      lastUpdated: data['lastUpdated'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'type': inventoryItemTypeToString(type),
      'quantity': quantity,
      'minQuantity': minQuantity,
      'lastUpdated': lastUpdated,
    };
  }

  InventoryBalanceModel copyWith({
    String? id,
    String? itemId,
    InventoryItemType? type,
    double? quantity,
    double? minQuantity,
    Timestamp? lastUpdated,
  }) {
    return InventoryBalanceModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
