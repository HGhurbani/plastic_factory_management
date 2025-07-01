// plastic_factory_management/lib/domain/repositories/inventory_repository.dart

import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/template_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_model.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'dart:io';
import 'dart:typed_data';

abstract class InventoryRepository {
  Stream<List<RawMaterialModel>> getRawMaterials();
  Future<void> addRawMaterial(RawMaterialModel material);
  Future<void> updateRawMaterial(RawMaterialModel material);
  Future<void> deleteRawMaterial(String materialId);

  // Template operations
  Stream<List<TemplateModel>> getTemplates();
  Future<void> addTemplate(TemplateModel template);
  Future<void> updateTemplate(TemplateModel template);
  Future<void> deleteTemplate(String templateId);
  Future<TemplateModel?> getTemplateById(String templateId);

  Stream<List<ProductModel>> getProducts();
  Future<ProductModel?> getProductById(String productId);
  Future<void> addProduct(ProductModel product,
      {File? imageFile, Uint8List? imageBytes});
  Future<void> updateProduct(ProductModel product,
      {File? newImageFile, Uint8List? newImageBytes});
  Future<void> deleteProduct(String productId);

  // --- Spare Parts ---
  Stream<List<SparePartModel>> getSpareParts();
  Future<void> addSparePart(SparePartModel sparePart);
  Future<void> updateSparePart(SparePartModel sparePart);
  Future<void> deleteSparePart(String sparePartId);

  // --- Inventory Balances ---
  Stream<List<InventoryBalanceModel>> getInventoryBalances(InventoryItemType type);
  Future<void> updateInventoryQuantity({
    required String itemId,
    required InventoryItemType type,
    required double delta,
  });
}
