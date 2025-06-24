// plastic_factory_management/lib/domain/usecases/inventory_usecases.dart

import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/domain/repositories/inventory_repository.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart'; // لاستخدام Timestamp

class InventoryUseCases {
  final InventoryRepository repository;

  InventoryUseCases(this.repository);

  // --- Raw Materials Use Cases ---

  Stream<List<RawMaterialModel>> getRawMaterials() {
    return repository.getRawMaterials();
  }

  Future<void> addRawMaterial({
    required String name,
    required double currentQuantity,
    required String unit,
    required double minStockLevel,
  }) async {
    final newMaterial = RawMaterialModel(
      id: '', // Firestore will generate
      name: name,
      currentQuantity: currentQuantity,
      unit: unit,
      minStockLevel: minStockLevel,
      lastUpdated: Timestamp.now(),
    );
    await repository.addRawMaterial(newMaterial);
  }

  Future<void> updateRawMaterial({
    required String id,
    required String name,
    required double currentQuantity,
    required String unit,
    required double minStockLevel,
  }) async {
    final updatedMaterial = RawMaterialModel(
      id: id,
      name: name,
      currentQuantity: currentQuantity,
      unit: unit,
      minStockLevel: minStockLevel,
      lastUpdated: Timestamp.now(),
    );
    await repository.updateRawMaterial(updatedMaterial);
  }

  Future<void> deleteRawMaterial(String materialId) async {
    await repository.deleteRawMaterial(materialId);
  }

  // --- Product Catalog Use Cases ---

  Stream<List<ProductModel>> getProducts() {
    return repository.getProducts();
  }

  Future<ProductModel?> getProductById(String productId) {
    return repository.getProductById(productId);
  }

  Future<void> addProduct({
    required String productCode,
    required String name,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
    required List<ProductMaterial> billOfMaterials,
    required List<String> colors,
    required List<String> additives,
    required String packagingType,
    required bool requiresPackaging,
    required bool requiresSticker,
    required String productType,
    required double expectedProductionTimePerUnit,
  }) async {
    final newProduct = ProductModel(
      id: '', // Firestore will generate
      productCode: productCode,
      name: name,
      description: description,
      billOfMaterials: billOfMaterials,
      colors: colors,
      additives: additives,
      packagingType: packagingType,
      requiresPackaging: requiresPackaging,
      requiresSticker: requiresSticker,
      productType: productType,
      expectedProductionTimePerUnit: expectedProductionTimePerUnit,
    );
    await repository.addProduct(newProduct,
        imageFile: imageFile, imageBytes: imageBytes);
  }

  Future<void> updateProduct({
    required String id,
    required String productCode,
    required String name,
    String? description,
    File? newImageFile,
    Uint8List? newImageBytes,
    String? existingImageUrl, // لتمرير الرابط الحالي في حال عدم تغيير الصورة
    required List<ProductMaterial> billOfMaterials,
    required List<String> colors,
    required List<String> additives,
    required String packagingType,
    required bool requiresPackaging,
    required bool requiresSticker,
    required String productType,
    required double expectedProductionTimePerUnit,
  }) async {
    final updatedProduct = ProductModel(
      id: id,
      productCode: productCode,
      name: name,
      description: description,
      imageUrl: existingImageUrl, // استخدم الرابط الموجود
      billOfMaterials: billOfMaterials,
      colors: colors,
      additives: additives,
      packagingType: packagingType,
      requiresPackaging: requiresPackaging,
      requiresSticker: requiresSticker,
      productType: productType,
      expectedProductionTimePerUnit: expectedProductionTimePerUnit,
    );
    await repository.updateProduct(updatedProduct,
        newImageFile: newImageFile, newImageBytes: newImageBytes);
  }

  Future<void> deleteProduct(String productId) async {
    await repository.deleteProduct(productId);
  }
}