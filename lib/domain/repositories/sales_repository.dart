// plastic_factory_management/lib/domain/repositories/sales_repository.dart

import 'package:plastic_factory_management/data/models/customer_model.dart';
import 'package:plastic_factory_management/data/models/sales_order_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'dart:io';
import 'dart:typed_data';

abstract class SalesRepository {
  Stream<List<CustomerModel>> getCustomers();
  Future<void> addCustomer(CustomerModel customer);
  Future<void> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String customerId);
  Future<CustomerModel?> getCustomerById(String customerId);

  Stream<List<SalesOrderModel>> getSalesOrders();
  Stream<List<SalesOrderModel>> getSalesOrdersBySalesRepresentative(String salesRepUid);
  Future<void> addSalesOrder(
    SalesOrderModel order, {
    File? signatureFile,
    Uint8List? signatureBytes,
  });
  Future<void> updateSalesOrder(SalesOrderModel order);
  Future<void> deleteSalesOrder(String orderId);
  Future<SalesOrderModel?> getSalesOrderById(String orderId);

  Stream<List<ProductModel>> getAllProducts(); // For sales reps to view products
}