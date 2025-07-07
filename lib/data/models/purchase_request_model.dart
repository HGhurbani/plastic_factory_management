import 'package:cloud_firestore/cloud_firestore.dart';

enum PurchaseRequestStatus {
  awaitingApproval, // بانتظار اعتماد المحاسب
  awaitingWarehouse, // بانتظار أمين المخزن
  completed, // تم استلام المشتريات
  rejected, // مرفوض من المحاسب
}

extension PurchaseRequestStatusExtension on PurchaseRequestStatus {
  String toFirestoreString() => name;
  static PurchaseRequestStatus fromString(String status) {
    return PurchaseRequestStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => PurchaseRequestStatus.awaitingApproval,
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
  final String? accountantUid;
  final String? accountantName;
  final Timestamp? accountantApprovedAt;
  final String? warehouseUid;
  final String? warehouseName;
  final Timestamp? warehouseReceivedAt;

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
    this.accountantUid,
    this.accountantName,
    this.accountantApprovedAt,
    this.warehouseUid,
    this.warehouseName,
    this.warehouseReceivedAt,
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
      status: PurchaseRequestStatusExtension.fromString(data['status'] ?? 'awaitingApproval'),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      supplierId: data['supplierId'],
      supplierName: data['supplierName'],
      accountantUid: data['accountantUid'],
      accountantName: data['accountantName'],
      accountantApprovedAt: data['accountantApprovedAt'],
      warehouseUid: data['warehouseUid'],
      warehouseName: data['warehouseName'],
      warehouseReceivedAt: data['warehouseReceivedAt'],
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
      'accountantUid': accountantUid,
      'accountantName': accountantName,
      'accountantApprovedAt': accountantApprovedAt,
      'warehouseUid': warehouseUid,
      'warehouseName': warehouseName,
      'warehouseReceivedAt': warehouseReceivedAt,
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
    String? accountantUid,
    String? accountantName,
    Timestamp? accountantApprovedAt,
    String? warehouseUid,
    String? warehouseName,
    Timestamp? warehouseReceivedAt,
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
      accountantUid: accountantUid ?? this.accountantUid,
      accountantName: accountantName ?? this.accountantName,
      accountantApprovedAt: accountantApprovedAt ?? this.accountantApprovedAt,
      warehouseUid: warehouseUid ?? this.warehouseUid,
      warehouseName: warehouseName ?? this.warehouseName,
      warehouseReceivedAt: warehouseReceivedAt ?? this.warehouseReceivedAt,
    );
  }
}
