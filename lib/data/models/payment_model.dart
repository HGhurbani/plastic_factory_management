import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final Timestamp paymentDate;
  final String method;
  final String? notes;
  final String recordedByUid;
  final String recordedByName;

  PaymentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paymentDate,
    required this.method,
    this.notes,
    required this.recordedByUid,
    required this.recordedByName,
  });

  factory PaymentModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: data['paymentDate'] ?? Timestamp.now(),
      method: data['method'] ?? 'cash',
      notes: data['notes'],
      recordedByUid: data['recordedByUid'] ?? '',
      recordedByName: data['recordedByName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'paymentDate': paymentDate,
      'method': method,
      'notes': notes,
      'recordedByUid': recordedByUid,
      'recordedByName': recordedByName,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    double? amount,
    Timestamp? paymentDate,
    String? method,
    String? notes,
    String? recordedByUid,
    String? recordedByName,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      recordedByUid: recordedByUid ?? this.recordedByUid,
      recordedByName: recordedByName ?? this.recordedByName,
    );
  }
}
