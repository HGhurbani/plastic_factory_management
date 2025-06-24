// plastic_factory_management/lib/domain/repositories/inventory_repository.dart

import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'dart:io';
import 'dart:typed_data';

abstract class InventoryRepository {
  Stream<List<RawMaterialModel>> getRawMaterials();
  Future<void> addRawMaterial(RawMaterialModel material);
  Future<void> updateRawMaterial(RawMaterialModel material);
  Future<void> deleteRawMaterial(String materialId);

  Stream<List<ProductModel>> getProducts();
  Future<ProductModel?> getProductById(String productId);
  Future<void> addProduct(ProductModel product,
      {File? imageFile, Uint8List? imageBytes});
  Future<void> updateProduct(ProductModel product,
      {File? newImageFile, Uint8List? newImageBytes});
  Future<void> deleteProduct(String productId);
}