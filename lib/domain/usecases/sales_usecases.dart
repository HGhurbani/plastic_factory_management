// plastic_factory_management/lib/domain/usecases/sales_usecases.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/customer_model.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/user_model.dart';
import 'package:plastic_factory_management/domain/repositories/sales_repository.dart';
import 'dart:io';
import 'notification_usecases.dart';
import 'user_usecases.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'package:plastic_factory_management/core/services/file_upload_service.dart';

class SalesUseCases {
  final SalesRepository repository;
  final NotificationUseCases notificationUseCases;
  final UserUseCases userUseCases;

  SalesUseCases(this.repository, this.notificationUseCases, this.userUseCases);

  // --- Customer Use Cases ---

  Stream<List<CustomerModel>> getCustomers() {
    return repository.getCustomers();
  }

  Future<void> addCustomer({
    required String name,
    required String contactPerson,
    required String phone,
    String? email,
    String? address,
  }) async {
    final newCustomer = CustomerModel(
      id: '', // Firestore will generate
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      address: address,
      createdAt: Timestamp.now(),
    );
    await repository.addCustomer(newCustomer);
  }

  Future<void> updateCustomer({
    required String id,
    required String name,
    required String contactPerson,
    required String phone,
    String? email,
    String? address,
  }) async {
    final updatedCustomer = CustomerModel(
      id: id,
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      address: address,
      createdAt: (await repository.getCustomerById(id))?.createdAt ?? Timestamp.now(), // Preserve creation date
    );
    await repository.updateCustomer(updatedCustomer);
  }

  Future<void> deleteCustomer(String customerId) async {
    await repository.deleteCustomer(customerId);
  }

  // --- Sales Order Use Cases ---

  Stream<List<SalesOrderModel>> getSalesOrders({String? salesRepUid}) {
    if (salesRepUid != null) {
      return repository.getSalesOrdersBySalesRepresentative(salesRepUid);
    }
    return repository.getSalesOrders();
  }

  Future<void> createSalesOrder({
    required CustomerModel customer,
    required UserModel salesRepresentative,
    required List<SalesOrderItem> orderItems,
    required double totalAmount,
    File? customerSignatureFile,
  }) async {
    final newOrder = SalesOrderModel(
      id: '', // Firestore will generate
      customerId: customer.id,
      customerName: customer.name,
      salesRepresentativeUid: salesRepresentative.uid,
      salesRepresentativeName: salesRepresentative.name,
      orderItems: orderItems,
      totalAmount: totalAmount,
      status: SalesOrderStatus.pendingApproval, // Initial status awaiting accountant
      createdAt: Timestamp.now(),
    );
    await repository.addSalesOrder(newOrder, signatureFile: customerSignatureFile);

    // Notify accountants for financial approval
    final accountants = await userUseCases.getUsersByRole(UserRole.accountant);
    for (final acc in accountants) {
      await notificationUseCases.sendNotification(
        userId: acc.uid,
        title: 'طلب مبيعات جديد',
        message:
            'قام ${salesRepresentative.name} بإنشاء طلب مبيعات للعميل ${customer.name}',
      );
    }
  }

  Future<void> updateSalesOrderStatus(String orderId, SalesOrderStatus newStatus) async {
    final order = await repository.getSalesOrders().first.then((orders) => orders.firstWhere((o) => o.id == orderId));
    if (order != null) {
      final updatedOrder = order.copyWith(status: newStatus);
      await repository.updateSalesOrder(updatedOrder);
    }
  }

  // Accountant approves a sales order
  Future<void> approveSalesOrder(SalesOrderModel order, UserModel accountant) async {
    final updatedOrder = order.copyWith(
      status: SalesOrderStatus.pendingFulfillment,
      approvedByUid: accountant.uid,
      approvedAt: Timestamp.now(),
      rejectionReason: null,
      moldTasksEnabled: true,
    );
    await repository.updateSalesOrder(updatedOrder);

    final managers = await userUseCases.getUsersByRole(UserRole.factoryManager);
    for (final m in managers) {
      await notificationUseCases.sendNotification(
        userId: m.uid,
        title: 'تم اعتماد طلب مبيعات',
        message: 'اعتمد المحاسب الطلب للعميل ${order.customerName}',
      );
    }
  }

  // Accountant rejects a sales order
  Future<void> rejectSalesOrder(SalesOrderModel order, UserModel accountant, String reason) async {
    final updatedOrder = order.copyWith(
      status: SalesOrderStatus.rejected,
      approvedByUid: accountant.uid,
      approvedAt: Timestamp.now(),
      rejectionReason: reason,
      moldTasksEnabled: false,
    );
    await repository.updateSalesOrder(updatedOrder);

    final salesRep = await userUseCases.getUserById(order.salesRepresentativeUid);
    if (salesRep != null) {
      await notificationUseCases.sendNotification(
        userId: salesRep.uid,
        title: 'تم رفض طلب المبيعات',
        message: 'تم رفض طلب العميل ${order.customerName}. السبب: $reason',
      );
    }
  }

  // Mold installer adds documentation
  Future<void> addMoldInstallationDocs({
    required SalesOrderModel order,
    String? notes,
    List<File>? attachments,
  }) async {
    List<String> uploaded = List<String>.from(order.moldInstallationImages);
    if (attachments != null && attachments.isNotEmpty) {
      for (final file in attachments) {
        final url = await FileUploadService().uploadFile(
          file,
          'sales_mold_docs/${order.id}_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        if (url != null) uploaded.add(url);
      }
    }
    final updatedOrder = order.copyWith(
      moldInstallationNotes: notes ?? order.moldInstallationNotes,
      moldInstallationImages: uploaded,
    );
    await repository.updateSalesOrder(updatedOrder);
  }

  Future<void> deleteSalesOrder(String orderId) async {
    await repository.deleteSalesOrder(orderId);
  }

  // --- Product Catalog for Sales Reps ---
  Stream<List<ProductModel>> getProductCatalogForSales() {
    return repository.getAllProducts(); // Reusing the product model from inventory
  }
}