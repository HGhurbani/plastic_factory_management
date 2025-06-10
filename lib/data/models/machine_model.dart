// plastic_factory_management/lib/data/models/machine_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum for Machine Status
enum MachineStatus {
  ready,          // جاهز للعمل
  inOperation,    // قيد العمل
  underMaintenance, // تحت الصيانة
  outOfService,   // خارج الخدمة
}

extension MachineStatusExtension on MachineStatus {
  String toArabicString() {
    switch (this) {
      case MachineStatus.ready:
        return 'جاهز';
      case MachineStatus.inOperation:
        return 'قيد العمل';
      case MachineStatus.underMaintenance:
        return 'تحت الصيانة';
      case MachineStatus.outOfService:
        return 'خارج الخدمة';
      default:
        return 'غير معروف';
    }
  }

  String toFirestoreString() {
    return name; // e.g., 'ready', 'inOperation'
  }

  static MachineStatus fromString(String status) {
    try {
      return MachineStatus.values.firstWhere((e) => e.name == status);
    } catch (e) {
      return MachineStatus.ready; // Default to ready if unknown
    }
  }
}

class MachineModel {
  final String id; // Firestore document ID
  final String name;
  final String machineId; // رقم المكينة (يمكن أن يكون معرفًا بشريًا)
  final String? details; // تفاصيل/مواصفات المكينة
  final double costPerHour; // تكلفة الساعة لتشغيل الآلة
  final MachineStatus status; // حالة المكينة الحالية
  final Timestamp? lastMaintenance; // تاريخ آخر صيانة

  MachineModel({
    required this.id,
    required this.name,
    required this.machineId,
    this.details,
    required this.costPerHour,
    required this.status,
    this.lastMaintenance,
  });

  factory MachineModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MachineModel(
      id: doc.id,
      name: data['name'] ?? '',
      machineId: data['machineId'] ?? '',
      details: data['details'],
      costPerHour: (data['costPerHour'] as num?)?.toDouble() ?? 0.0,
      status: MachineStatusExtension.fromString(data['status'] ?? 'ready'),
      lastMaintenance: data['lastMaintenance'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'machineId': machineId,
      'details': details,
      'costPerHour': costPerHour,
      'status': status.toFirestoreString(),
      'lastMaintenance': lastMaintenance,
    };
  }

  MachineModel copyWith({
    String? id,
    String? name,
    String? machineId,
    String? details,
    double? costPerHour,
    MachineStatus? status,
    Timestamp? lastMaintenance,
  }) {
    return MachineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      machineId: machineId ?? this.machineId,
      details: details ?? this.details,
      costPerHour: costPerHour ?? this.costPerHour,
      status: status ?? this.status,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
    );
  }
}