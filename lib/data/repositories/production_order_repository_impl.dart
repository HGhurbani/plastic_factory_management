import 'package:plastic_factory_management/data/datasources/production_order_datasource.dart';
import 'package:plastic_factory_management/data/models/production_order_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'production_order_repository.dart';

class ProductionOrderRepositoryImpl implements ProductionOrderRepository {
  final ProductionOrderDatasource datasource;

  ProductionOrderRepositoryImpl(this.datasource);

  @override
  Stream<List<ProductionOrderModel>> getProductionOrders() {
    return datasource.getProductionOrders();
  }

  @override
  Stream<List<ProductionOrderModel>> getPendingProductionOrders() {
    return datasource.getPendingProductionOrders();
  }

  @override
  Future<ProductionOrderModel?> getProductionOrderById(String orderId) {
    return datasource.getProductionOrderById(orderId);
  }

  @override
  Future<ProductionOrderModel> createProductionOrder(ProductionOrderModel order) {
    return datasource.createProductionOrder(order);
  }

  @override
  Future<void> updateProductionOrder(ProductionOrderModel order) {
    return datasource.updateProductionOrder(order);
  }

  @override
  Future<void> deleteProductionOrder(String orderId) {
    return datasource.deleteProductionOrder(orderId);
  }

  @override
  Stream<List<ProductModel>> getProducts() {
    return datasource.getProducts();
  }

  @override
  Future<ProductModel?> getProductById(String productId) {
    return datasource.getProductById(productId);
  }

  @override
  Stream<List<RawMaterialModel>> getRawMaterials() {
    return datasource.getRawMaterials();
  }
}
