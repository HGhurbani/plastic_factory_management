// plastic_factory_management/lib/data/models/operator_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum for Operator Status
enum OperatorStatus {
  available, // متاح للعمل
  busy,      // مشغول حالياً بمهمة
  onBreak,   // في استراحة
  absent,    // غائب
}

extension OperatorStatusExtension on OperatorStatus {
  String toArabicString() {
    switch (this) {
      case OperatorStatus.available:
        return 'متاح';
      case OperatorStatus.busy:
        return 'مشغول';
      case OperatorStatus.onBreak:
        return 'في استراحة';
      case OperatorStatus.absent:
        return 'غائب';
      default:
        return 'غير معروف';
    }
  }

  String toFirestoreString() {
    return name;
  }

  static OperatorStatus fromString(String status) {
    try {
      return OperatorStatus.values.firstWhere((e) => e.name == status);
    } catch (e) {
      return OperatorStatus.available; // Default to available
    }
  }
}

class OperatorModel {
  final String id; // Firestore document ID
  final String name;
  final String employeeId; // رقم الموظف (معرف فريد للموظف)
  final String? personalData; // بيانات شخصية إضافية (اختياري)
  final double costPerHour; // تكلفة المشغل بالساعة
  final String? currentMachineId; // ID الآلة التي يشغلها حالياً (إذا كان busy)
  final OperatorStatus status; // حالة المشغل

  OperatorModel({
    required this.id,
    required this.name,
    required this.employeeId,
    this.personalData,
    required this.costPerHour,
    this.currentMachineId,
    required this.status,
  });

  factory OperatorModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OperatorModel(
      id: doc.id,
      name: data['name'] ?? '',
      employeeId: data['employeeId'] ?? '',
      personalData: data['personalData'],
      costPerHour: (data['costPerHour'] as num?)?.toDouble() ?? 0.0,
      currentMachineId: data['currentMachineId'],
      status: OperatorStatusExtension.fromString(data['status'] ?? 'available'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'employeeId': employeeId,
      'personalData': personalData,
      'costPerHour': costPerHour,
      'currentMachineId': currentMachineId,
      'status': status.toFirestoreString(),
    };
  }

  OperatorModel copyWith({
    String? id,
    String? name,
    String? employeeId,
    String? personalData,
    double? costPerHour,
    String? currentMachineId,
    OperatorStatus? status,
  }) {
    return OperatorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      personalData: personalData ?? this.personalData,
      costPerHour: costPerHour ?? this.costPerHour,
      currentMachineId: currentMachineId ?? this.currentMachineId,
      status: status ?? this.status,
    );
  }
}