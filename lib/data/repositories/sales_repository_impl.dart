// plastic_factory_management/lib/data/repositories/sales_repository_impl.dart

import 'package:plastic_factory_management/data/datasources/sales_datasource.dart';
import 'package:plastic_factory_management/data/models/customer_model.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/domain/repositories/sales_repository.dart'; // سنقوم بإنشاء هذا لاحقاً
import 'dart:io';
import 'dart:typed_data';

class SalesRepositoryImpl implements SalesRepository {
  final SalesDatasource datasource;

  SalesRepositoryImpl(this.datasource);

  @override
  Stream<List<CustomerModel>> getCustomers() {
    return datasource.getCustomers();
  }

  @override
  Future<void> addCustomer(CustomerModel customer) {
    return datasource.addCustomer(customer);
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) {
    return datasource.updateCustomer(customer);
  }

  @override
  Future<void> deleteCustomer(String customerId) {
    return datasource.deleteCustomer(customerId);
  }

  @override
  Future<CustomerModel?> getCustomerById(String customerId) {
    return datasource.getCustomerById(customerId);
  }

  @override
  Stream<List<SalesOrderModel>> getSalesOrders() {
    return datasource.getSalesOrders();
  }

  @override
  Stream<List<SalesOrderModel>> getSalesOrdersBySalesRepresentative(String salesRepUid) {
    return datasource.getSalesOrdersBySalesRepresentative(salesRepUid);
  }

  @override
  Future<void> addSalesOrder(
    SalesOrderModel order, {
    File? signatureFile,
    Uint8List? signatureBytes,
  }) {
    return datasource.addSalesOrder(
      order,
      signatureFile: signatureFile,
      signatureBytes: signatureBytes,
    );
  }

  @override
  Future<void> updateSalesOrder(SalesOrderModel order) {
    return datasource.updateSalesOrder(order);
  }

  @override
  Future<void> deleteSalesOrder(String orderId) {
    return datasource.deleteSalesOrder(orderId);
  }

  @override
  Future<SalesOrderModel?> getSalesOrderById(String orderId) {
    return datasource.getSalesOrderById(orderId);
  }

  @override
  Stream<List<ProductModel>> getAllProducts() {
    return datasource.getAllProducts();
  }
}