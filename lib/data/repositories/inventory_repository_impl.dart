import 'package:plastic_factory_management/data/datasources/inventory_datasource.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/template_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_model.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'package:plastic_factory_management/domain/repositories/inventory_repository.dart';
import 'dart:io';
import 'dart:typed_data';

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

  // --- Templates ---
  @override
  Stream<List<TemplateModel>> getTemplates() {
    return datasource.getTemplates();
  }

  @override
  Future<void> addTemplate(TemplateModel template) {
    return datasource.addTemplate(template);
  }

  @override
  Future<void> updateTemplate(TemplateModel template) {
    return datasource.updateTemplate(template);
  }

  @override
  Future<void> deleteTemplate(String templateId) {
    return datasource.deleteTemplate(templateId);
  }

  @override
  Future<TemplateModel?> getTemplateById(String templateId) {
    return datasource.getTemplateById(templateId);
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
  Future<void> addProduct(ProductModel product,
      {File? imageFile, Uint8List? imageBytes}) {
    return datasource.addProduct(product,
        imageFile: imageFile, imageBytes: imageBytes);
  }

  @override
  Future<void> updateProduct(ProductModel product,
      {File? newImageFile, Uint8List? newImageBytes}) {
    return datasource.updateProduct(product,
        newImageFile: newImageFile, newImageBytes: newImageBytes);
  }

  @override
  Future<void> deleteProduct(String productId) {
    return datasource.deleteProduct(productId);
  }

  // --- Spare Parts ---
  @override
  Stream<List<SparePartModel>> getSpareParts() {
    return datasource.getSpareParts();
  }

  @override
  Future<void> addSparePart(SparePartModel sparePart) {
    return datasource.addSparePart(sparePart);
  }

  @override
  Future<void> updateSparePart(SparePartModel sparePart) {
    return datasource.updateSparePart(sparePart);
  }

  @override
  Future<void> deleteSparePart(String sparePartId) {
    return datasource.deleteSparePart(sparePartId);
  }

  // --- Inventory Balances ---
  @override
  Stream<List<InventoryBalanceModel>> getInventoryBalances(InventoryItemType type) {
    return datasource.getInventoryBalances(type);
  }

  @override
  Future<InventoryBalanceModel?> getInventoryBalance(
      String itemId, InventoryItemType type) {
    return datasource.getInventoryBalance(itemId, type);
  }

  @override
  Future<void> updateInventoryQuantity({
    required String itemId,
    required InventoryItemType type,
    required double delta,
  }) {
    return datasource.updateInventoryQuantity(
      itemId: itemId,
      type: type,
      delta: delta,
    );
  }
}
