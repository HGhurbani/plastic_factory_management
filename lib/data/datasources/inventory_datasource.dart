// plastic_factory_management/lib/data/datasources/inventory_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plastic_factory_management/core/services/file_upload_service.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'dart:io';

class InventoryDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FileUploadService _uploadService = FileUploadService();

  // --- Raw Materials Operations ---

  Stream<List<RawMaterialModel>> getRawMaterials() {
    return _firestore.collection('raw_materials').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => RawMaterialModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  Future<void> addRawMaterial(RawMaterialModel material) async {
    await _firestore.collection('raw_materials').add(material.toMap());
  }

  Future<void> updateRawMaterial(RawMaterialModel material) async {
    await _firestore.collection('raw_materials').doc(material.id).update(material.toMap());
  }

  Future<void> deleteRawMaterial(String materialId) async {
    await _firestore.collection('raw_materials').doc(materialId).delete();
  }

  // --- Product Catalog Operations ---

  Stream<List<ProductModel>> getProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromDocumentSnapshot(doc)).toList();
    });
  }

  Future<ProductModel?> getProductById(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (doc.exists) {
      return ProductModel.fromDocumentSnapshot(doc);
    }
    return null;
  }

  Future<void> addProduct(ProductModel product, {File? imageFile}) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadService.uploadFile(
        imageFile,
        'product_images/${product.productCode}_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
    }
    final docRef = await _firestore.collection('products').add(product.copyWith(imageUrl: imageUrl).toMap());
    // Update the product model with the Firestore generated ID if needed for local use
  }

  Future<void> updateProduct(ProductModel product, {File? newImageFile}) async {
    String? imageUrl = product.imageUrl; // Keep existing image URL by default
    if (newImageFile != null) {
      imageUrl = await _uploadService.uploadFile(
        newImageFile,
        'product_images/${product.productCode}_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
    }
    await _firestore.collection('products').doc(product.id).update(product.copyWith(imageUrl: imageUrl).toMap());
  }

  Future<void> deleteProduct(String productId) async {
    final product = await getProductById(productId);
    // TODO: implement deletion of image from remote server if needed
    await _firestore.collection('products').doc(productId).delete();
  }
}