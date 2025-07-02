import 'package:cloud_firestore/cloud_firestore.dart';

enum SparePartRequestStatus { pendingApproval, approved, rejected, fulfilled }

extension SparePartRequestStatusExtension on SparePartRequestStatus {
  String toFirestoreString() => name;
  static SparePartRequestStatus fromString(String status) {
    return SparePartRequestStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => SparePartRequestStatus.pendingApproval,
    );
  }
}

class SparePartRequestItem {
  final String partId;
  final String partName;
  final int quantity;
  final double unitPrice;

  SparePartRequestItem({
    required this.partId,
    required this.partName,
    required this.quantity,
    required this.unitPrice,
  });

  factory SparePartRequestItem.fromMap(Map<String, dynamic> map) {
    return SparePartRequestItem(
      partId: map['partId'] ?? '',
      partName: map['partName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partId': partId,
      'partName': partName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class SparePartRequestModel {
  final String id;
  final String requesterUid;
  final String requesterName;
  final List<SparePartRequestItem> items;
  final double totalAmount;
  final SparePartRequestStatus status;
  final Timestamp createdAt;
  final String? approvedByUid;
  final String? approvedByName;
  final Timestamp? approvedAt;
  final String? rejectionReason;

  SparePartRequestModel({
    required this.id,
    required this.requesterUid,
    required this.requesterName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.approvedByUid,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
  });

  factory SparePartRequestModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SparePartRequestModel(
      id: doc.id,
      requesterUid: data['requesterUid'] ?? '',
      requesterName: data['requesterName'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => SparePartRequestItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: SparePartRequestStatusExtension.fromString(data['status'] ?? 'pendingApproval'),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      approvedByUid: data['approvedByUid'],
      approvedByName: data['approvedByName'],
      approvedAt: data['approvedAt'],
      rejectionReason: data['rejectionReason'],
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
      'approvedByUid': approvedByUid,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt,
      'rejectionReason': rejectionReason,
    };
  }

  SparePartRequestModel copyWith({
    String? id,
    String? requesterUid,
    String? requesterName,
    List<SparePartRequestItem>? items,
    double? totalAmount,
    SparePartRequestStatus? status,
    Timestamp? createdAt,
    String? approvedByUid,
    String? approvedByName,
    Timestamp? approvedAt,
    String? rejectionReason,
  }) {
    return SparePartRequestModel(
      id: id ?? this.id,
      requesterUid: requesterUid ?? this.requesterUid,
      requesterName: requesterName ?? this.requesterName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedByUid: approvedByUid ?? this.approvedByUid,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
