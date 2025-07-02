// plastic_factory_management/lib/data/models/maintenance_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum for Maintenance Type
enum MaintenanceType {
  preventive, // صيانة وقائية
  corrective, // صيانة تصحيحية
  breakdown,  // عطل طارئ (تصحيحية غير مخطط لها)
}

// Asset types for maintenance
enum MaintenanceAssetType { machine, mold, vehicle, equipment }

extension MaintenanceAssetTypeExtension on MaintenanceAssetType {
  String toArabicString() {
    switch (this) {
      case MaintenanceAssetType.machine:
        return 'مكينة';
      case MaintenanceAssetType.mold:
        return 'قالب';
      case MaintenanceAssetType.vehicle:
        return 'سيارة';
      case MaintenanceAssetType.equipment:
        return 'معدة';
    }
  }

  String toFirestoreString() => name;

  static MaintenanceAssetType fromString(String type) {
    try {
      return MaintenanceAssetType.values.firstWhere((e) => e.name == type);
    } catch (_) {
      return MaintenanceAssetType.machine;
    }
  }
}

// Spare part usage for maintenance logs
class MaintenanceSparePart {
  final String partId;
  final String partName;
  final double quantity;

  MaintenanceSparePart({required this.partId, required this.partName, required this.quantity});

  factory MaintenanceSparePart.fromMap(Map<String, dynamic> map) => MaintenanceSparePart(
        partId: map['partId'] ?? '',
        partName: map['partName'] ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'partId': partId,
        'partName': partName,
        'quantity': quantity,
      };

  MaintenanceSparePart copyWith({String? partId, String? partName, double? quantity}) {
    return MaintenanceSparePart(
      partId: partId ?? this.partId,
      partName: partName ?? this.partName,
      quantity: quantity ?? this.quantity,
    );
  }
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
  final MaintenanceAssetType assetType; // نوع الأصل
  final String responsibleUid; // UID للمسؤول عن الصيانة
  final String responsibleName; // اسم المسؤول عن الصيانة
  final String? notes; // ملاحظات إضافية حول الصيانة
  final double? meterReading; // قراءة العداد
  final List<MaintenanceSparePart> sparePartsUsed; // قطع الغيار المستخدمة
  final List<MaintenanceChecklistItem> checklist; // قائمة التحقق من المهام المنجزة
  final String status; // حالة سجل الصيانة (scheduled, in_progress, completed, cancelled)

  MaintenanceLogModel({
    required this.id,
    required this.machineId,
    required this.machineName,
    required this.maintenanceDate,
    required this.type,
    required this.assetType,
    required this.responsibleUid,
    required this.responsibleName,
    this.notes,
    this.meterReading,
    this.sparePartsUsed = const [],
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
      assetType: MaintenanceAssetTypeExtension.fromString(data['assetType'] ?? 'machine'),
      responsibleUid: data['responsibleUid'] ?? '',
      responsibleName: data['responsibleName'] ?? '',
      notes: data['notes'],
      meterReading: (data['meterReading'] as num?)?.toDouble(),
      sparePartsUsed: (data['sparePartsUsed'] as List<dynamic>?)
              ?.map((e) => MaintenanceSparePart.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      'assetType': assetType.toFirestoreString(),
      'responsibleUid': responsibleUid,
      'responsibleName': responsibleName,
      'notes': notes,
      'meterReading': meterReading,
      'sparePartsUsed': sparePartsUsed.map((e) => e.toMap()).toList(),
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
    MaintenanceAssetType? assetType,
    String? responsibleUid,
    String? responsibleName,
    String? notes,
    double? meterReading,
    List<MaintenanceSparePart>? sparePartsUsed,
    List<MaintenanceChecklistItem>? checklist,
    String? status,
  }) {
    return MaintenanceLogModel(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      machineName: machineName ?? this.machineName,
      maintenanceDate: maintenanceDate ?? this.maintenanceDate,
      type: type ?? this.type,
      assetType: assetType ?? this.assetType,
      responsibleUid: responsibleUid ?? this.responsibleUid,
      responsibleName: responsibleName ?? this.responsibleName,
      notes: notes ?? this.notes,
      meterReading: meterReading ?? this.meterReading,
      sparePartsUsed: sparePartsUsed ?? this.sparePartsUsed,
      checklist: checklist ?? this.checklist,
      status: status ?? this.status,
    );
  }
}