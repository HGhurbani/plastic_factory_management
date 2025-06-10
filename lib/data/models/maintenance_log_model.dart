// plastic_factory_management/lib/data/models/maintenance_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum for Maintenance Type
enum MaintenanceType {
  preventive, // صيانة وقائية
  corrective, // صيانة تصحيحية
  breakdown,  // عطل طارئ (تصحيحية غير مخطط لها)
}

extension MaintenanceTypeExtension on MaintenanceType {
  String toArabicString() {
    switch (this) {
      case MaintenanceType.preventive:
        return 'وقائية';
      case MaintenanceType.corrective:
        return 'تصحيحية';
      case MaintenanceType.breakdown:
        return 'عطل طارئ';
      default:
        return 'غير معروف';
    }
  }

  String toFirestoreString() {
    return name; // e.g., 'preventive', 'corrective'
  }

  static MaintenanceType fromString(String type) {
    try {
      return MaintenanceType.values.firstWhere((e) => e.name == type);
    } catch (e) {
      return MaintenanceType.preventive; // Default if unknown
    }
  }
}

// Model for a single checklist item within a maintenance task
class MaintenanceChecklistItem {
  final String task; // وصف المهمة في القائمة (مثال: 'تنظيف الفلاتر')
  final bool completed; // هل تم إكمال هذه المهمة؟
  final Timestamp? completedAt; // وقت إكمال المهمة

  MaintenanceChecklistItem({
    required this.task,
    this.completed = false,
    this.completedAt,
  });

  factory MaintenanceChecklistItem.fromMap(Map<String, dynamic> map) {
    return MaintenanceChecklistItem(
      task: map['task'] ?? '',
      completed: map['completed'] ?? false,
      completedAt: map['completedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'completed': completed,
      'completedAt': completedAt,
    };
  }

  MaintenanceChecklistItem copyWith({
    String? task,
    bool? completed,
    Timestamp? completedAt,
  }) {
    return MaintenanceChecklistItem(
      task: task ?? this.task,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class MaintenanceLogModel {
  final String id; // Firestore document ID
  final String machineId; // ID الآلة التي تمت صيانتها
  final String machineName; // اسم الآلة (للعرض السريع)
  final Timestamp maintenanceDate; // تاريخ الصيانة
  final MaintenanceType type; // نوع الصيانة (وقائية/تصحيحية/عطل)
  final String responsibleUid; // UID للمسؤول عن الصيانة
  final String responsibleName; // اسم المسؤول عن الصيانة
  final String? notes; // ملاحظات إضافية حول الصيانة
  final List<MaintenanceChecklistItem> checklist; // قائمة التحقق من المهام المنجزة
  final String status; // حالة سجل الصيانة (scheduled, in_progress, completed, cancelled)

  MaintenanceLogModel({
    required this.id,
    required this.machineId,
    required this.machineName,
    required this.maintenanceDate,
    required this.type,
    required this.responsibleUid,
    required this.responsibleName,
    this.notes,
    this.checklist = const [],
    required this.status,
  });

  factory MaintenanceLogModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaintenanceLogModel(
      id: doc.id,
      machineId: data['machineId'] ?? '',
      machineName: data['machineName'] ?? '',
      maintenanceDate: data['maintenanceDate'] ?? Timestamp.now(),
      type: MaintenanceTypeExtension.fromString(data['type'] ?? 'preventive'),
      responsibleUid: data['responsibleUid'] ?? '',
      responsibleName: data['responsibleName'] ?? '',
      notes: data['notes'],
      checklist: (data['checklist'] as List<dynamic>?)
          ?.map((item) => MaintenanceChecklistItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      status: data['status'] ?? 'scheduled',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'machineId': machineId,
      'machineName': machineName,
      'maintenanceDate': maintenanceDate,
      'type': type.toFirestoreString(),
      'responsibleUid': responsibleUid,
      'responsibleName': responsibleName,
      'notes': notes,
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'status': status,
    };
  }

  MaintenanceLogModel copyWith({
    String? id,
    String? machineId,
    String? machineName,
    Timestamp? maintenanceDate,
    MaintenanceType? type,
    String? responsibleUid,
    String? responsibleName,
    String? notes,
    List<MaintenanceChecklistItem>? checklist,
    String? status,
  }) {
    return MaintenanceLogModel(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      machineName: machineName ?? this.machineName,
      maintenanceDate: maintenanceDate ?? this.maintenanceDate,
      type: type ?? this.type,
      responsibleUid: responsibleUid ?? this.responsibleUid,
      responsibleName: responsibleName ?? this.responsibleName,
      notes: notes ?? this.notes,
      checklist: checklist ?? this.checklist,
      status: status ?? this.status,
    );
  }
}