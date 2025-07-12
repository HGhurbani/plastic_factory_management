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
  final double? receivingMeterReading;
  final String? receivingNotes;
  final Timestamp createdAt;
  final Timestamp? receivedAt;

  ShiftHandoverModel({
    required this.id,
    required this.orderId,
    required this.fromSupervisorUid,
    required this.fromSupervisorName,
    required this.toSupervisorUid,
    required this.toSupervisorName,
    required this.meterReading,
    this.notes,
    this.receivingMeterReading,
    this.receivingNotes,
    required this.createdAt,
    this.receivedAt,
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
      receivingMeterReading:
          (data['receivingMeterReading'] as num?)?.toDouble(),
      receivingNotes: data['receivingNotes'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      receivedAt: data['receivedAt'] as Timestamp?,
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
      'receivingMeterReading': receivingMeterReading,
      'receivingNotes': receivingNotes,
      'createdAt': createdAt,
      'receivedAt': receivedAt,
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
    double? receivingMeterReading,
    String? receivingNotes,
    Timestamp? createdAt,
    Timestamp? receivedAt,
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
      receivingMeterReading:
          receivingMeterReading ?? this.receivingMeterReading,
      receivingNotes: receivingNotes ?? this.receivingNotes,
      createdAt: createdAt ?? this.createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}
