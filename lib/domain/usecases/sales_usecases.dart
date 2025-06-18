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
      status: SalesOrderStatus.pendingFulfillment, // Initial status
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

  Future<void> deleteSalesOrder(String orderId) async {
    await repository.deleteSalesOrder(orderId);
  }

  // --- Product Catalog for Sales Reps ---
  Stream<List<ProductModel>> getProductCatalogForSales() {
    return repository.getAllProducts(); // Reusing the product model from inventory
  }
}