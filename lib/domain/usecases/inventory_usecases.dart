// plastic_factory_management/lib/domain/usecases/inventory_usecases.dart

import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'package:plastic_factory_management/data/models/template_model.dart';
import 'package:plastic_factory_management/data/models/spare_part_model.dart';
import 'package:plastic_factory_management/data/models/inventory_balance_model.dart';
import 'package:plastic_factory_management/domain/repositories/inventory_repository.dart';
import 'package:plastic_factory_management/domain/usecases/notification_usecases.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/core/constants/app_enums.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart'; // لاستخدام Timestamp

class InventoryUseCases {
  final InventoryRepository repository;
  final NotificationUseCases notificationUseCases;
  final UserUseCases userUseCases;

  InventoryUseCases(this.repository, this.notificationUseCases, this.userUseCases);

  // --- Raw Materials Use Cases ---

  Stream<List<RawMaterialModel>> getRawMaterials() {
    return repository.getRawMaterials();
  }

  Future<void> addRawMaterial({
    required String code,
    required String name,
    required String unit,
  }) async {
    final newMaterial = RawMaterialModel(
      id: '', // Firestore will generate
      code: code,
      name: name,
      unit: unit,
      lastUpdated: Timestamp.now(),
    );
    await repository.addRawMaterial(newMaterial);
  }

  Future<void> updateRawMaterial({
    required String id,
    required String code,
    required String name,
    required String unit,
  }) async {
    final updatedMaterial = RawMaterialModel(
      id: id,
      code: code,
      name: name,
      unit: unit,
      lastUpdated: Timestamp.now(),
    );
    await repository.updateRawMaterial(updatedMaterial);
  }

  Future<void> deleteRawMaterial(String materialId) async {
    await repository.deleteRawMaterial(materialId);
  }

  // --- Template Use Cases ---
  Stream<List<TemplateModel>> getTemplates() {
    return repository.getTemplates();
  }

  Future<void> addTemplate({
    required String code,
    required String name,
    required double weight,
    required double costPerHour,
    required List<TemplateMaterial> materialsUsed,
    required List<String> colors,
    required List<String> productionInputs,
  }) async {
    final newTemplate = TemplateModel(
      id: '',
      code: code,
      name: name,
      weight: weight,
      costPerHour: costPerHour,
      materialsUsed: materialsUsed,
      colors: colors,
      productionInputs: productionInputs,
    );
    await repository.addTemplate(newTemplate);
  }

  Future<void> updateTemplate({
    required String id,
    required String code,
    required String name,
    required double weight,
    required double costPerHour,
    required List<TemplateMaterial> materialsUsed,
    required List<String> colors,
    required List<String> productionInputs,
  }) async {
    final updated = TemplateModel(
      id: id,
      code: code,
      name: name,
      weight: weight,
      costPerHour: costPerHour,
      materialsUsed: materialsUsed,
      colors: colors,
      productionInputs: productionInputs,
    );
    await repository.updateTemplate(updated);
  }

  Future<void> deleteTemplate(String templateId) async {
    await repository.deleteTemplate(templateId);
  }

  Future<TemplateModel?> getTemplateById(String templateId) {
    return repository.getTemplateById(templateId);
  }

  Future<List<TemplateModel>> getTemplatesByIds(List<String> ids) async {
    final all = await repository.getTemplates().first;
    return all.where((t) => ids.contains(t.id)).toList();
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
    List<String> templateIds = const [],
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
      templateIds: templateIds,
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
    List<String>? templateIds,
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
      templateIds: templateIds ?? [],
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

  // --- Spare Parts Use Cases ---

  Stream<List<SparePartModel>> getSpareParts() {
    return repository.getSpareParts();
  }

  Future<void> addSparePart({
    required String code,
    required String name,
    required String unit,
  }) async {
    final part = SparePartModel(
      id: '',
      code: code,
      name: name,
      unit: unit,
      lastUpdated: Timestamp.now(),
    );
    await repository.addSparePart(part);
  }

  Future<void> updateSparePart({
    required String id,
    required String code,
    required String name,
    required String unit,
  }) async {
    final part = SparePartModel(
      id: id,
      code: code,
      name: name,
      unit: unit,
      lastUpdated: Timestamp.now(),
    );
    await repository.updateSparePart(part);
  }

  Future<void> deleteSparePart(String id) async {
    await repository.deleteSparePart(id);
  }

  // --- Inventory Balance Use Cases ---

  Stream<List<InventoryBalanceModel>> getInventoryBalances(InventoryItemType type) {
    return repository.getInventoryBalances(type);
  }

  Future<InventoryBalanceModel?> getInventoryBalance(
      String itemId, InventoryItemType type) {
    return repository.getInventoryBalance(itemId, type);
  }

  Future<double> getAvailableQuantity(
      String itemId, InventoryItemType type) async {
    final balance = await repository.getInventoryBalance(itemId, type);
    return balance?.quantity ?? 0;
  }

  Future<void> adjustInventory({
    required String itemId,
    required InventoryItemType type,
    required double delta,
  }) {
    return repository.updateInventoryQuantity(
      itemId: itemId,
      type: type,
      delta: delta,
    );
  }

  Future<void> adjustInventoryWithNotification({
    required String itemId,
    required InventoryItemType type,
    required double delta,
    required String itemName,
  }) async {
    await adjustInventory(itemId: itemId, type: type, delta: delta);
    final balances = await repository.getInventoryBalances(type).first;
    final record = balances.firstWhere(
      (b) => b.itemId == itemId,
      orElse: () => InventoryBalanceModel(
        id: '',
        itemId: itemId,
        type: type,
        quantity: 0,
        minQuantity: 0,
      ),
    );
    if (record.quantity <= record.minQuantity) {
      final roles = [
        UserRole.productionManager,
        UserRole.salesRepresentative,
        UserRole.maintenanceManager,
        UserRole.inventoryManager,
      ];
      for (final role in roles) {
        final users = await userUseCases.getUsersByRole(role);
        for (final u in users) {
          await notificationUseCases.sendNotification(
            userId: u.uid,
            title: 'نقص المخزون',
            message: '$itemName أقل من الحد المسموح',
          );
        }
      }
    }
  }
}