// plastic_factory_management/lib/data/datasources/sales_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/core/services/file_upload_service.dart';
import 'package:plastic_factory_management/data/models/customer_model.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart'; // لجلب المنتجات من المخزون
import 'dart:io';

class SalesDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FileUploadService _uploadService = FileUploadService();

  // --- Customer Operations ---

  Stream<List<CustomerModel>> getCustomers() {
    return _firestore.collection('customers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CustomerModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  Future<void> addCustomer(CustomerModel customer) async {
    await _firestore.collection('customers').add(customer.toMap());
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await _firestore.collection('customers').doc(customer.id).update(customer.toMap());
  }

  Future<void> deleteCustomer(String customerId) async {
    await _firestore.collection('customers').doc(customerId).delete();
  }

  Future<CustomerModel?> getCustomerById(String customerId) async {
    final doc = await _firestore.collection('customers').doc(customerId).get();
    if (doc.exists) {
      return CustomerModel.fromDocumentSnapshot(doc);
    }
    return null;
  }

  // --- Sales Order Operations ---

  Stream<List<SalesOrderModel>> getSalesOrders() {
    return _firestore.collection('sales_orders').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SalesOrderModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  Stream<List<SalesOrderModel>> getSalesOrdersBySalesRepresentative(String salesRepUid) {
    return _firestore.collection('sales_orders').where('salesRepresentativeUid', isEqualTo: salesRepUid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SalesOrderModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  Future<void> addSalesOrder(SalesOrderModel order, {File? signatureFile}) async {
    String? signatureUrl;
    if (signatureFile != null) {
      signatureUrl = await _uploadService.uploadFile(
        signatureFile,
        'customer_signatures/${order.customerId}_${order.id}_${DateTime.now().microsecondsSinceEpoch}.png',
      );
    }
    await _firestore.collection('sales_orders').add(order.copyWith(customerSignatureUrl: signatureUrl).toMap());
  }

  Future<void> updateSalesOrder(SalesOrderModel order) async {
    await _firestore.collection('sales_orders').doc(order.id).update(order.toMap());
  }

  Future<void> deleteSalesOrder(String orderId) async {
    // Optional: delete associated signature from storage
    await _firestore.collection('sales_orders').doc(orderId).delete();
  }

  // --- Product Data Access (for product catalog viewing and order creation) ---
  Stream<List<ProductModel>> getAllProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromDocumentSnapshot(doc)).toList();
    });
  }
}