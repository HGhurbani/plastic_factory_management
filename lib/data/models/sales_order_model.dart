// plastic_factory_management/lib/data/models/sales_order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';

// Enum for Sales Order Status
enum SalesOrderStatus {
  pendingApproval,    // بانتظار اعتماد المحاسب
  pendingFulfillment, // بانتظار قرار منسق طلبات الإنتاج
  warehouseProcessing, // لدى أمين المخزن للتجهيز
  awaitingMoldApproval, // بانتظار اعتماد مشرف القوالب
  inProduction,       // قيد الإنتاج بعد تحديد موعد التسليم
  fulfilled,          // تم التوريد
  canceled,           // ملغي
  rejected,           // مرفوض من المحاسب
}

extension SalesOrderStatusExtension on SalesOrderStatus {
  String toArabicString() {
    switch (this) {
      case SalesOrderStatus.pendingApproval:
        return 'بانتظار الاعتماد';
      case SalesOrderStatus.pendingFulfillment:
        return 'بانتظار منسق الطلبات';
      case SalesOrderStatus.warehouseProcessing:
        return 'قيد التحضير بالمخزن';
      case SalesOrderStatus.awaitingMoldApproval:
        return 'بانتظار اعتماد القوالب';
      case SalesOrderStatus.inProduction:
        return 'قيد الإنتاج';
      case SalesOrderStatus.fulfilled:
        return 'تم التوريد';
      case SalesOrderStatus.canceled:
        return 'ملغي';
      case SalesOrderStatus.rejected:
        return 'مرفوض';
      default:
        return 'غير معروف';
    }
  }

  String toFirestoreString() {
    return name; // e.g., 'pendingFulfillment', 'fulfilled'
  }

  static SalesOrderStatus fromString(String status) {
    try {
      return SalesOrderStatus.values.firstWhere((e) => e.name == status);
    } catch (e) {
      return SalesOrderStatus.pendingApproval; // Default if unknown
    }
  }
}

// Represents a single item in a sales order
class SalesOrderItem {
  final String productId; // ID المنتج
  final String productName; // اسم المنتج
  final int quantity; // الكمية المطلوبة
  final double unitPrice; // سعر الوحدة (يمكن أن يتغير مع الزمن)
  final String? quantityUnit; // وحدة القياس للكمية

  SalesOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.quantityUnit,
  });

  factory SalesOrderItem.fromMap(Map<String, dynamic> map) {
    return SalesOrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantityUnit: map['quantityUnit'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'quantityUnit': quantityUnit,
    };
  }
}

class SalesOrderModel {
  final String id; // Firestore document ID
  final String customerId; // ID العميل
  final String customerName; // اسم العميل (للعرض السريع)
  final String salesRepresentativeUid; // UID لمندوب المبيعات الذي أنشأ الطلب
  final String salesRepresentativeName; // اسم مندوب المبيعات
  final List<SalesOrderItem> orderItems; // قائمة الأصناف المطلوبة
  final double totalAmount; // المبلغ الإجمالي للطلب
  final SalesOrderStatus status; // حالة الطلب
  final Timestamp createdAt; // تاريخ إنشاء الطلب
  final String? customerSignatureUrl; // رابط صورة توقيع العميل
  final String? approvedByUid; // UID المحاسب الذي اعتمد الطلب
  final String? approvedByName; // اسم المحاسب الذي اعتمد الطلب
  final Timestamp? approvedAt; // وقت الاعتماد
  final String? approvalNotes; // ملاحظات الاعتماد من المحاسب
  final String? rejectionReason; // سبب الرفض إن وجد
  final bool moldTasksEnabled; // هل تم تفعيل مهام تركيب القوالب
  final String? moldSupervisorUid; // UID مشرف التركيب الذي اعتمد الطلب
  final String? moldSupervisorName; // اسم مشرف التركيب
  final Timestamp? moldSupervisorApprovedAt; // وقت اعتماد المشرف
  final String? moldInstallationNotes; // ملاحظات عملية التركيب
  final List<String> moldInstallationImages; // صور توثيقية للتركيب
  final String? operationsNotes; // ملاحظات مسؤول العمليات
  final String? warehouseNotes; // ملاحظات أمين المخزن
  final List<String> warehouseImages; // صور توثيق المخزن
  final String? warehouseManagerUid; // UID أمين المخزن المسؤول
  final String? warehouseManagerName; // اسم أمين المخزن المسؤول
  final Timestamp? deliveryTime; // موعد التسليم المحدد من أمين المخزن
  final TransportMode? transportMode; // وسيلة النقل
  final String? driverUid; // UID السائق
  final String? driverName; // اسم السائق
  final String? productionManagerUid; // UID مسؤول الإنتاج
  final String? productionManagerName; // اسم مسؤول الإنتاج
  final String? productionRejectionReason; // سبب رفض الإنتاج

  SalesOrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.salesRepresentativeUid,
    required this.salesRepresentativeName,
    required this.orderItems,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.customerSignatureUrl,
    this.approvedByUid,
    this.approvedByName,
    this.approvedAt,
    this.approvalNotes,
    this.rejectionReason,
    this.moldTasksEnabled = false,
    this.moldSupervisorUid,
    this.moldSupervisorName,
    this.moldSupervisorApprovedAt,
    this.moldInstallationNotes,
    this.moldInstallationImages = const [],
    this.operationsNotes,
    this.warehouseNotes,
    this.warehouseImages = const [],
    this.warehouseManagerUid,
    this.warehouseManagerName,
    this.deliveryTime,
    this.transportMode,
    this.driverUid,
    this.driverName,
    this.productionManagerUid,
    this.productionManagerName,
    this.productionRejectionReason,
  });

  factory SalesOrderModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesOrderModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      salesRepresentativeUid: data['salesRepresentativeUid'] ?? '',
      salesRepresentativeName: data['salesRepresentativeName'] ?? '',
      orderItems: (data['orderItems'] as List<dynamic>?)
          ?.map((item) => SalesOrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: SalesOrderStatusExtension.fromString(data['status'] ?? 'pendingApproval'),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      customerSignatureUrl: data['customerSignatureUrl'],
      approvedByUid: data['approvedByUid'],
      approvedByName: data['approvedByName'],
      approvedAt: data['approvedAt'],
      approvalNotes: data['approvalNotes'],
      rejectionReason: data['rejectionReason'],
      moldTasksEnabled: data['moldTasksEnabled'] ?? false,
      moldSupervisorUid: data['moldSupervisorUid'],
      moldSupervisorName: data['moldSupervisorName'],
      moldSupervisorApprovedAt: data['moldSupervisorApprovedAt'],
      moldInstallationNotes: data['moldInstallationNotes'],
      moldInstallationImages: List<String>.from(data['moldInstallationImages'] ?? []),
      operationsNotes: data['operationsNotes'],
      warehouseNotes: data['warehouseNotes'],
      warehouseImages: List<String>.from(data['warehouseImages'] ?? []),
      warehouseManagerUid: data['warehouseManagerUid'],
      warehouseManagerName: data['warehouseManagerName'],
      deliveryTime: data['deliveryTime'],
      transportMode: data['transportMode'] != null
          ? TransportModeExtension.fromString(data['transportMode'])
          : null,
      driverUid: data['driverUid'],
      driverName: data['driverName'],
      productionManagerUid: data['productionManagerUid'],
      productionManagerName: data['productionManagerName'],
      productionRejectionReason: data['productionRejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'salesRepresentativeUid': salesRepresentativeUid,
      'salesRepresentativeName': salesRepresentativeName,
      'orderItems': orderItems.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.toFirestoreString(),
      'createdAt': createdAt,
      'customerSignatureUrl': customerSignatureUrl,
      'approvedByUid': approvedByUid,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt,
      'approvalNotes': approvalNotes,
      'rejectionReason': rejectionReason,
      'moldTasksEnabled': moldTasksEnabled,
      'moldSupervisorUid': moldSupervisorUid,
      'moldSupervisorName': moldSupervisorName,
      'moldSupervisorApprovedAt': moldSupervisorApprovedAt,
      'moldInstallationNotes': moldInstallationNotes,
      'moldInstallationImages': moldInstallationImages,
      'operationsNotes': operationsNotes,
      'warehouseNotes': warehouseNotes,
      'warehouseImages': warehouseImages,
      'warehouseManagerUid': warehouseManagerUid,
      'warehouseManagerName': warehouseManagerName,
      'deliveryTime': deliveryTime,
      'transportMode': transportMode?.toFirestoreString(),
      'driverUid': driverUid,
      'driverName': driverName,
      'productionManagerUid': productionManagerUid,
      'productionManagerName': productionManagerName,
      'productionRejectionReason': productionRejectionReason,
    };
  }

  SalesOrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? salesRepresentativeUid,
    String? salesRepresentativeName,
    List<SalesOrderItem>? orderItems,
    double? totalAmount,
    SalesOrderStatus? status,
    Timestamp? createdAt,
    String? customerSignatureUrl,
    String? approvedByUid,
    String? approvedByName,
    Timestamp? approvedAt,
    String? approvalNotes,
    String? rejectionReason,
    bool? moldTasksEnabled,
    String? moldSupervisorUid,
    String? moldSupervisorName,
    Timestamp? moldSupervisorApprovedAt,
    String? moldInstallationNotes,
    List<String>? moldInstallationImages,
    String? operationsNotes,
    String? warehouseNotes,
    List<String>? warehouseImages,
    String? warehouseManagerUid,
    String? warehouseManagerName,
    Timestamp? deliveryTime,
    TransportMode? transportMode,
    String? driverUid,
    String? driverName,
    String? productionManagerUid,
    String? productionManagerName,
    String? productionRejectionReason,
  }) {
    return SalesOrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      salesRepresentativeUid: salesRepresentativeUid ?? this.salesRepresentativeUid,
      salesRepresentativeName: salesRepresentativeName ?? this.salesRepresentativeName,
      orderItems: orderItems ?? this.orderItems,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customerSignatureUrl: customerSignatureUrl ?? this.customerSignatureUrl,
      approvedByUid: approvedByUid ?? this.approvedByUid,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      approvalNotes: approvalNotes ?? this.approvalNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      moldTasksEnabled: moldTasksEnabled ?? this.moldTasksEnabled,
      moldSupervisorUid: moldSupervisorUid ?? this.moldSupervisorUid,
      moldSupervisorName: moldSupervisorName ?? this.moldSupervisorName,
      moldSupervisorApprovedAt: moldSupervisorApprovedAt ?? this.moldSupervisorApprovedAt,
      moldInstallationNotes: moldInstallationNotes ?? this.moldInstallationNotes,
      moldInstallationImages: moldInstallationImages ?? this.moldInstallationImages,
      operationsNotes: operationsNotes ?? this.operationsNotes,
      warehouseNotes: warehouseNotes ?? this.warehouseNotes,
      warehouseImages: warehouseImages ?? this.warehouseImages,
      warehouseManagerUid: warehouseManagerUid ?? this.warehouseManagerUid,
      warehouseManagerName: warehouseManagerName ?? this.warehouseManagerName,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      transportMode: transportMode ?? this.transportMode,
      driverUid: driverUid ?? this.driverUid,
      driverName: driverName ?? this.driverName,
      productionManagerUid: productionManagerUid ?? this.productionManagerUid,
      productionManagerName: productionManagerName ?? this.productionManagerName,
      productionRejectionReason: productionRejectionReason ?? this.productionRejectionReason,
    );
  }
}