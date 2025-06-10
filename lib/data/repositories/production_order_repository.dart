// plastic_factory_management/lib/domain/repositories/production_order_repository.dart

import 'package:plastic_factory_management/data/models/production_order_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';

abstract class ProductionOrderRepository {
  Stream<List<ProductionOrderModel>> getProductionOrders();
  Stream<List<ProductionOrderModel>> getPendingProductionOrders();
  Future<ProductionOrderModel?> getProductionOrderById(String orderId);
  Future<void> createProductionOrder(ProductionOrderModel order);
  Future<void> updateProductionOrder(ProductionOrderModel order);
  Future<void> deleteProductionOrder(String orderId);

  // For product and raw material selection in order creation
  Stream<List<ProductModel>> getProducts();
  Future<ProductModel?> getProductById(String productId);
  Stream<List<RawMaterialModel>> getRawMaterials();
}