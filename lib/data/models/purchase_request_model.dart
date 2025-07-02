import 'package:cloud_firestore/cloud_firestore.dart';

enum PurchaseRequestStatus {
  pendingInventory,
  awaitingSupplier,
  awaitingFinance,
  completed,
}

extension PurchaseRequestStatusExtension on PurchaseRequestStatus {
  String toFirestoreString() => name;
  static PurchaseRequestStatus fromString(String status) {
    return PurchaseRequestStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => PurchaseRequestStatus.pendingInventory,
    );
  }
}

class PurchaseRequestItem {
  final String itemId;
  final String itemName;
  final int quantity;
  PurchaseRequestItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
  });

  factory PurchaseRequestItem.fromMap(Map<String, dynamic> map) {
    return PurchaseRequestItem(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: map['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
    };
  }
}

class PurchaseRequestModel {
  final String id;
  final String requesterUid;
  final String requesterName;
  final List<PurchaseRequestItem> items;
  final double totalAmount;
  final PurchaseRequestStatus status;
  final Timestamp createdAt;
  final String? supplierId;
  final String? supplierName;
  final String? financeUid;
  final String? financeName;
  final Timestamp? financeApprovedAt;

  PurchaseRequestModel({
    required this.id,
    required this.requesterUid,
    required this.requesterName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.supplierId,
    this.supplierName,
    this.financeUid,
    this.financeName,
    this.financeApprovedAt,
  });

  factory PurchaseRequestModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseRequestModel(
      id: doc.id,
      requesterUid: data['requesterUid'] ?? '',
      requesterName: data['requesterName'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => PurchaseRequestItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: PurchaseRequestStatusExtension.fromString(data['status'] ?? 'pendingInventory'),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      supplierId: data['supplierId'],
      supplierName: data['supplierName'],
      financeUid: data['financeUid'],
      financeName: data['financeName'],
      financeApprovedAt: data['financeApprovedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterUid': requesterUid,
      'requesterName': requesterName,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.toFirestoreString(),
      'createdAt': createdAt,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'financeUid': financeUid,
      'financeName': financeName,
      'financeApprovedAt': financeApprovedAt,
    };
  }

  PurchaseRequestModel copyWith({
    String? id,
    String? requesterUid,
    String? requesterName,
    List<PurchaseRequestItem>? items,
    double? totalAmount,
    PurchaseRequestStatus? status,
    Timestamp? createdAt,
    String? supplierId,
    String? supplierName,
    String? financeUid,
    String? financeName,
    Timestamp? financeApprovedAt,
  }) {
    return PurchaseRequestModel(
      id: id ?? this.id,
      requesterUid: requesterUid ?? this.requesterUid,
      requesterName: requesterName ?? this.requesterName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      financeUid: financeUid ?? this.financeUid,
      financeName: financeName ?? this.financeName,
      financeApprovedAt: financeApprovedAt ?? this.financeApprovedAt,
    );
  }
}
