// plastic_factory_management/lib/data/models/sales_order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum for Sales Order Status
enum SalesOrderStatus {
  pendingFulfillment, // بانتظار التوريد من المصنع
  fulfilled,          // تم التوريد
  canceled,           // ملغي
}

extension SalesOrderStatusExtension on SalesOrderStatus {
  String toArabicString() {
    switch (this) {
      case SalesOrderStatus.pendingFulfillment:
        return 'بانتظار التوريد';
      case SalesOrderStatus.fulfilled:
        return 'تم التوريد';
      case SalesOrderStatus.canceled:
        return 'ملغي';
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
      return SalesOrderStatus.pendingFulfillment; // Default if unknown
    }
  }
}

// Represents a single item in a sales order
class SalesOrderItem {
  final String productId; // ID المنتج
  final String productName; // اسم المنتج
  final int quantity; // الكمية المطلوبة
  final double unitPrice; // سعر الوحدة (يمكن أن يتغير مع الزمن)

  SalesOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  factory SalesOrderItem.fromMap(Map<String, dynamic> map) {
    return SalesOrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
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
      status: SalesOrderStatusExtension.fromString(data['status'] ?? 'pendingFulfillment'),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      customerSignatureUrl: data['customerSignatureUrl'],
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
    );
  }
}