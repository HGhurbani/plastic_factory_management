import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftHandoverModel {
  final String id;
  final String orderId;
  final String fromSupervisorUid;
  final String fromSupervisorName;
  final String toSupervisorUid;
  final String toSupervisorName;
  final double meterReading;
  final String? notes;
  final Timestamp createdAt;

  ShiftHandoverModel({
    required this.id,
    required this.orderId,
    required this.fromSupervisorUid,
    required this.fromSupervisorName,
    required this.toSupervisorUid,
    required this.toSupervisorName,
    required this.meterReading,
    this.notes,
    required this.createdAt,
  });

  factory ShiftHandoverModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShiftHandoverModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      fromSupervisorUid: data['fromSupervisorUid'] ?? '',
      fromSupervisorName: data['fromSupervisorName'] ?? '',
      toSupervisorUid: data['toSupervisorUid'] ?? '',
      toSupervisorName: data['toSupervisorName'] ?? '',
      meterReading: (data['meterReading'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'fromSupervisorUid': fromSupervisorUid,
      'fromSupervisorName': fromSupervisorName,
      'toSupervisorUid': toSupervisorUid,
      'toSupervisorName': toSupervisorName,
      'meterReading': meterReading,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  ShiftHandoverModel copyWith({
    String? id,
    String? orderId,
    String? fromSupervisorUid,
    String? fromSupervisorName,
    String? toSupervisorUid,
    String? toSupervisorName,
    double? meterReading,
    String? notes,
    Timestamp? createdAt,
  }) {
    return ShiftHandoverModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      fromSupervisorUid: fromSupervisorUid ?? this.fromSupervisorUid,
      fromSupervisorName: fromSupervisorName ?? this.fromSupervisorName,
      toSupervisorUid: toSupervisorUid ?? this.toSupervisorUid,
      toSupervisorName: toSupervisorName ?? this.toSupervisorName,
      meterReading: meterReading ?? this.meterReading,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
