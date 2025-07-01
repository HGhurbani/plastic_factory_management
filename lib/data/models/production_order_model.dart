// plastic_factory_management/lib/data/models/production_order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum for Production Order Status
enum ProductionOrderStatus {
  pending, // قيد الانتظار (للموافقة)
  approved, // معتمد (بعد موافقة المدير)
  inProduction, // قيد الإنتاج (العملية بدأت فعليًا على الآلة)
  completed, // مكتمل (المنتج النهائي جاهز)
  canceled, // ملغي
  rejected, // مرفوض (بعد مراجعة المدير)
}

extension ProductionOrderStatusExtension on ProductionOrderStatus {
  String toArabicString() {
    switch (this) {
      case ProductionOrderStatus.pending:
        return 'قيد الانتظار';
      case ProductionOrderStatus.approved:
        return 'معتمد';
      case ProductionOrderStatus.inProduction:
        return 'قيد الإنتاج';
      case ProductionOrderStatus.completed:
        return 'مكتمل';
      case ProductionOrderStatus.canceled:
        return 'ملغي';
      case ProductionOrderStatus.rejected:
        return 'مرفوض';
      default:
        return 'غير معروف';
    }
  }

  String toFirestoreString() {
    return name; // Simply return the enum name as a string (e.g., 'pending', 'approved')
  }

  static ProductionOrderStatus fromString(String status) {
    try {
      return ProductionOrderStatus.values.firstWhere(
            (e) => e.name == status,
      );
    } catch (e) {
      return ProductionOrderStatus.pending; // Default or unknown status
    }
  }
}

// Model for a single stage in the production workflow
class ProductionWorkflowStage {
  final String stageName; // اسم المرحلة (مثال: 'استلام مشرف تركيب القوالب', 'تركيب القالب', 'بدء الإنتاج')
  final String status; // حالة هذه المرحلة (pending, accepted, completed, in_progress, failed)
  final String? assignedToUid; // UID للمسؤول الحالي عن هذه المرحلة
  final String? assignedToName; // اسم المسؤول الحالي
  final String? machineId; // إذا كانت هذه المرحلة تتضمن آلة معينة
  final Timestamp? startedAt; // وقت بدء المرحلة الفعلية (مشغل المكينة/المشرف)
  final Timestamp? completedAt; // وقت انتهاء المرحلة الفعلية
  final Timestamp? acceptedAt; // وقت استلام المسؤولية (لمراحل التسليمات)
  final String? delayReason; // مبرر التأخير إذا تجاوز الوقت المتوقع (يتم إدخاله بواسطة المسؤول)
  final double? actualTimeMinutes; // الوقت الفعلي المستغرق لهذه المرحلة (بالدقائق)
  final String? signatureImageUrl; // رابط صورة التوقيع الرقمي (للتسليمات الحرجة)
  final List<String> attachments; // روابط صور مرفقة بالمرحلة (مثال: صور القالب بعد التركيب)
  final String? notes; // ملاحظات إضافية على هذه المرحلة

  ProductionWorkflowStage({
    required this.stageName,
    required this.status,
    this.assignedToUid,
    this.assignedToName,
    this.machineId,
    this.startedAt,
    this.completedAt,
    this.acceptedAt,
    this.delayReason,
    this.actualTimeMinutes,
    this.signatureImageUrl,
    this.attachments = const [],
    this.notes,
  });

  factory ProductionWorkflowStage.fromMap(Map<String, dynamic> map) {
    return ProductionWorkflowStage(
      stageName: map['stageName'] ?? '',
      status: map['status'] ?? 'pending',
      assignedToUid: map['assignedToUid'],
      assignedToName: map['assignedToName'],
      machineId: map['machineId'],
      startedAt: map['startedAt'] as Timestamp?,
      completedAt: map['completedAt'] as Timestamp?,
      acceptedAt: map['acceptedAt'] as Timestamp?,
      delayReason: map['delayReason'],
      actualTimeMinutes: (map['actualTimeMinutes'] as num?)?.toDouble(),
      signatureImageUrl: map['signatureImageUrl'],
      attachments: List<String>.from(map['attachments'] ?? []),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stageName': stageName,
      'status': status,
      'assignedToUid': assignedToUid,
      'assignedToName': assignedToName,
      'machineId': machineId,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'acceptedAt': acceptedAt,
      'delayReason': delayReason,
      'actualTimeMinutes': actualTimeMinutes,
      'signatureImageUrl': signatureImageUrl,
      'attachments': attachments,
      'notes': notes,
    };
  }

  // Helper method to create a copy with specific fields updated
  ProductionWorkflowStage copyWith({
    String? stageName,
    String? status,
    String? assignedToUid,
    String? assignedToName,
    String? machineId,
    Timestamp? startedAt,
    Timestamp? completedAt,
    Timestamp? acceptedAt,
    String? delayReason,
    double? actualTimeMinutes,
    String? signatureImageUrl,
    List<String>? attachments,
    String? notes,
  }) {
    return ProductionWorkflowStage(
      stageName: stageName ?? this.stageName,
      status: status ?? this.status,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedToName: assignedToName ?? this.assignedToName,
      machineId: machineId ?? this.machineId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      delayReason: delayReason ?? this.delayReason,
      actualTimeMinutes: actualTimeMinutes ?? this.actualTimeMinutes,
      signatureImageUrl: signatureImageUrl ?? this.signatureImageUrl,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
    );
  }
}

class ProductionOrderModel {
  final String id; // Firestore document ID
  final String productId; // Reference to product from products collection
  final String productName; // Redundant: Product Name (for easier display)
  final int requiredQuantity;
  final String batchNumber;
  final String? templateId; // القالب المستخدم
  final String? templateName;
  final String? machineId; // الآلة المستخدمة
  final String? machineName;
  final String? salesOrderId; // If this order was generated from a sales order
  final String orderPreparerUid; // UID of the user who prepared the order
  final String orderPreparerName;
  final String orderPreparerRole; // Role of the user who prepared the order
  final ProductionOrderStatus status; // Current overall status of the order (enum)
  final Timestamp createdAt;
  final String? approvedByUid; // UID of the manager who approved/rejected the order
  final Timestamp? approvedAt; // Timestamp of approval/rejection
  final String? rejectionReason;
  final String currentStage; // Current active stage name (e.g., 'انتظار الموافقة', 'استلام مشرف تركيب القوالب')
  final List<ProductionWorkflowStage> workflowStages; // Array of all workflow stages with their details

  ProductionOrderModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.requiredQuantity,
    required this.batchNumber,
    this.templateId,
    this.templateName,
    this.machineId,
    this.machineName,
    this.salesOrderId,
    required this.orderPreparerUid,
    required this.orderPreparerName,
    required this.orderPreparerRole,
    required this.status,
    required this.createdAt,
    this.approvedByUid,
    this.approvedAt,
    this.rejectionReason,
    required this.currentStage,
    required this.workflowStages,
  });

  factory ProductionOrderModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductionOrderModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      requiredQuantity: data['requiredQuantity'] ?? 0,
      batchNumber: data['batchNumber'] ?? '',
      templateId: data['templateId'],
      templateName: data['templateName'],
      machineId: data['machineId'],
      machineName: data['machineName'],
      salesOrderId: data['salesOrderId'],
      orderPreparerUid: data['orderPreparerUid'] ?? '',
      orderPreparerName: data['orderPreparerName'] ?? '',
      orderPreparerRole: data['orderPreparerRole'] ?? 'unknown',
      status: ProductionOrderStatusExtension.fromString(data['status'] ?? 'pending'),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      approvedByUid: data['approvedByUid'],
      approvedAt: data['approvedAt'] as Timestamp?,
      rejectionReason: data['rejectionReason'],
      currentStage: data['currentStage'] ?? '',
      workflowStages: (data['workflowStages'] as List<dynamic>?)
          ?.map((item) => ProductionWorkflowStage.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'requiredQuantity': requiredQuantity,
      'batchNumber': batchNumber,
      'templateId': templateId,
      'templateName': templateName,
      'machineId': machineId,
      'machineName': machineName,
      'salesOrderId': salesOrderId,
      'orderPreparerUid': orderPreparerUid,
      'orderPreparerName': orderPreparerName,
      'orderPreparerRole': orderPreparerRole,
      'status': status.toFirestoreString(),
      'createdAt': createdAt,
      'approvedByUid': approvedByUid,
      'approvedAt': approvedAt,
      'rejectionReason': rejectionReason,
      'currentStage': currentStage,
      'workflowStages': workflowStages.map((stage) => stage.toMap()).toList(),
    };
  }

  // Helper method to create a copy with specific fields updated
  ProductionOrderModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? requiredQuantity,
    String? batchNumber,
    String? templateId,
    String? templateName,
    String? machineId,
    String? machineName,
    String? salesOrderId,
    String? orderPreparerUid,
    String? orderPreparerName,
    String? orderPreparerRole,
    ProductionOrderStatus? status,
    Timestamp? createdAt,
    String? approvedByUid,
    Timestamp? approvedAt,
    String? rejectionReason,
    String? currentStage,
    List<ProductionWorkflowStage>? workflowStages,
  }) {
    return ProductionOrderModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      requiredQuantity: requiredQuantity ?? this.requiredQuantity,
      batchNumber: batchNumber ?? this.batchNumber,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      machineId: machineId ?? this.machineId,
      machineName: machineName ?? this.machineName,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      orderPreparerUid: orderPreparerUid ?? this.orderPreparerUid,
      orderPreparerName: orderPreparerName ?? this.orderPreparerName,
      orderPreparerRole: orderPreparerRole ?? this.orderPreparerRole,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedByUid: approvedByUid ?? this.approvedByUid,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      currentStage: currentStage ?? this.currentStage,
      workflowStages: workflowStages ?? this.workflowStages,
    );
  }
}