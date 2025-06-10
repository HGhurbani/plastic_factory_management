import 'package:plastic_factory_management/data/datasources/inventory_datasource.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/domain/repositories/inventory_repository.dart';
import 'dart:io';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryDatasource datasource;

  InventoryRepositoryImpl(this.datasource);

  // --- Raw Materials ---
  @override
  Stream<List<RawMaterialModel>> getRawMaterials() {
    return datasource.getRawMaterials();
  }

  @override
  Future<void> addRawMaterial(RawMaterialModel material) {
    return datasource.addRawMaterial(material);
  }

  @override
  Future<void> updateRawMaterial(RawMaterialModel material) {
    return datasource.updateRawMaterial(material);
  }

  @override
  Future<void> deleteRawMaterial(String materialId) {
    return datasource.deleteRawMaterial(materialId);
  }

  // --- Products ---
  @override
  Stream<List<ProductModel>> getProducts() {
    return datasource.getProducts();
  }

  @override
  Future<ProductModel?> getProductById(String productId) {
    return datasource.getProductById(productId);
  }

  @override
  Future<void> addProduct(ProductModel product, {File? imageFile}) {
    return datasource.addProduct(product, imageFile: imageFile);
  }

  @override
  Future<void> updateProduct(ProductModel product, {File? newImageFile}) {
    return datasource.updateProduct(product, newImageFile: newImageFile);
  }

  @override
  Future<void> deleteProduct(String productId) {
    return datasource.deleteProduct(productId);
  }
}
