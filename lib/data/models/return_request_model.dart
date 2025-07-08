import 'package:cloud_firestore/cloud_firestore.dart';

enum ReturnRequestStatus {
  pendingOperations,
  pendingSalesApproval,
  awaitingPickup,
  completed,
}

extension ReturnRequestStatusExtension on ReturnRequestStatus {
  String toFirestoreString() => name;
  static ReturnRequestStatus fromString(String status) {
    return ReturnRequestStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ReturnRequestStatus.pendingOperations,
    );
  }

  String toArabicString() {
    switch (this) {
      case ReturnRequestStatus.pendingOperations:
        return 'بانتظار مراجعة العمليات';
      case ReturnRequestStatus.pendingSalesApproval:
        return 'بانتظار اعتماد المبيعات';
      case ReturnRequestStatus.awaitingPickup:
        return 'بانتظار الاستلام';
      case ReturnRequestStatus.completed:
        return 'مكتمل';
    }
  }
}

class ReturnRequestModel {
  final String id;
  final String requesterUid;
  final String requesterName;
  final String salesOrderId;
  final String reason;
  final ReturnRequestStatus status;
  final Timestamp createdAt;
  final String? operationsUid;
  final String? operationsName;
  final Timestamp? operationsApprovedAt;
  final String? salesManagerUid;
  final String? salesManagerName;
  final Timestamp? salesApprovedAt;
  final String? driverName;
  final String? warehouseKeeperName;
  final Timestamp? pickupScheduledAt;

  ReturnRequestModel({
    required this.id,
    required this.requesterUid,
    required this.requesterName,
    required this.salesOrderId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.operationsUid,
    this.operationsName,
    this.operationsApprovedAt,
    this.salesManagerUid,
    this.salesManagerName,
    this.salesApprovedAt,
    this.driverName,
    this.warehouseKeeperName,
    this.pickupScheduledAt,
  });

  factory ReturnRequestModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReturnRequestModel(
      id: doc.id,
      requesterUid: data['requesterUid'] ?? '',
      requesterName: data['requesterName'] ?? '',
      salesOrderId: data['salesOrderId'] ?? '',
      reason: data['reason'] ?? '',
      status: ReturnRequestStatusExtension.fromString(data['status'] ?? 'pendingOperations'),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      operationsUid: data['operationsUid'],
      operationsName: data['operationsName'],
      operationsApprovedAt: data['operationsApprovedAt'],
      salesManagerUid: data['salesManagerUid'],
      salesManagerName: data['salesManagerName'],
      salesApprovedAt: data['salesApprovedAt'],
      driverName: data['driverName'],
      warehouseKeeperName: data['warehouseKeeperName'],
      pickupScheduledAt: data['pickupScheduledAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterUid': requesterUid,
      'requesterName': requesterName,
      'salesOrderId': salesOrderId,
      'reason': reason,
      'status': status.toFirestoreString(),
      'createdAt': createdAt,
      'operationsUid': operationsUid,
      'operationsName': operationsName,
      'operationsApprovedAt': operationsApprovedAt,
      'salesManagerUid': salesManagerUid,
      'salesManagerName': salesManagerName,
      'salesApprovedAt': salesApprovedAt,
      'driverName': driverName,
      'warehouseKeeperName': warehouseKeeperName,
      'pickupScheduledAt': pickupScheduledAt,
    };
  }

  ReturnRequestModel copyWith({
    String? id,
    String? requesterUid,
    String? requesterName,
    String? salesOrderId,
    String? reason,
    ReturnRequestStatus? status,
    Timestamp? createdAt,
    String? operationsUid,
    String? operationsName,
    Timestamp? operationsApprovedAt,
    String? salesManagerUid,
    String? salesManagerName,
    Timestamp? salesApprovedAt,
    String? driverName,
    String? warehouseKeeperName,
    Timestamp? pickupScheduledAt,
  }) {
    return ReturnRequestModel(
      id: id ?? this.id,
      requesterUid: requesterUid ?? this.requesterUid,
      requesterName: requesterName ?? this.requesterName,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      operationsUid: operationsUid ?? this.operationsUid,
      operationsName: operationsName ?? this.operationsName,
      operationsApprovedAt: operationsApprovedAt ?? this.operationsApprovedAt,
      salesManagerUid: salesManagerUid ?? this.salesManagerUid,
      salesManagerName: salesManagerName ?? this.salesManagerName,
      salesApprovedAt: salesApprovedAt ?? this.salesApprovedAt,
      driverName: driverName ?? this.driverName,
      warehouseKeeperName: warehouseKeeperName ?? this.warehouseKeeperName,
      pickupScheduledAt: pickupScheduledAt ?? this.pickupScheduledAt,
    );
  }
}
