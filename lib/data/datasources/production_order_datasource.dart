// plastic_factory_management/lib/data/datasources/production_order_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/data/models/production_order_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';

class ProductionOrderDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream production orders (e.g., for approval or tracking)
  Stream<List<ProductionOrderModel>> getProductionOrders() {
    return _firestore.collection('production_orders').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductionOrderModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  // Stream pending production orders for managers
  Stream<List<ProductionOrderModel>> getPendingProductionOrders() {
    return _firestore
        .collection('production_orders')
        .where('status', isEqualTo: ProductionOrderStatus.pending.toFirestoreString())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProductionOrderModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  // Get a single production order by ID
  Future<ProductionOrderModel?> getProductionOrderById(String orderId) async {
    final doc = await _firestore.collection('production_orders').doc(orderId).get();
    if (doc.exists) {
      return ProductionOrderModel.fromDocumentSnapshot(doc);
    }
    return null;
  }

  // Create a new production order
  Future<void> createProductionOrder(ProductionOrderModel order) async {
    await _firestore.collection('production_orders').add(order.toMap());
  }

  // Update an existing production order
  Future<void> updateProductionOrder(ProductionOrderModel order) async {
    await _firestore.collection('production_orders').doc(order.id).update(order.toMap());
  }

  // Delete a production order
  Future<void> deleteProductionOrder(String orderId) async {
    await _firestore.collection('production_orders').doc(orderId).delete();
  }

  // --- Product & Raw Material related methods (for dropdowns/selection) ---

  // Stream all products for selection in production order form
  Stream<List<ProductModel>> getProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  // Get a single product by ID
  Future<ProductModel?> getProductById(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (doc.exists) {
      return ProductModel.fromDocumentSnapshot(doc);
    }
    return null;
  }

  // Get all raw materials (e.g., for displaying BOM or checking stock)
  Stream<List<RawMaterialModel>> getRawMaterials() {
    return _firestore.collection('raw_materials').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => RawMaterialModel.fromDocumentSnapshot(doc)).toList();
    });
  }
}