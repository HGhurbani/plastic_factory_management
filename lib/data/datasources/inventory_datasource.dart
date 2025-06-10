// plastic_factory_management/lib/data/datasources/inventory_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:plastic_factory_management/data/models/raw_material_model.dart';
import 'package:plastic_factory_management/data/models/product_model.dart';
import 'dart:io';

class InventoryDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      final ref = _storage.ref().child('product_images/${product.productCode}_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }
    final docRef = await _firestore.collection('products').add(product.copyWith(imageUrl: imageUrl).toMap());
    // Update the product model with the Firestore generated ID if needed for local use
  }

  Future<void> updateProduct(ProductModel product, {File? newImageFile}) async {
    String? imageUrl = product.imageUrl; // Keep existing image URL by default
    if (newImageFile != null) {
      // Delete old image if it exists
      if (product.imageUrl != null && product.imageUrl!.startsWith('gs://')) {
        try {
          await _storage.refFromURL(product.imageUrl!).delete();
        } catch (e) {
          print('Error deleting old product image: $e');
        }
      }
      // Upload new image
      final ref = _storage.ref().child('product_images/${product.productCode}_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await ref.putFile(newImageFile);
      imageUrl = await ref.getDownloadURL();
    }
    await _firestore.collection('products').doc(product.id).update(product.copyWith(imageUrl: imageUrl).toMap());
  }

  Future<void> deleteProduct(String productId) async {
    final product = await getProductById(productId);
    if (product != null && product.imageUrl != null && product.imageUrl!.startsWith('gs://')) {
      try {
        await _storage.refFromURL(product.imageUrl!).delete();
      } catch (e) {
        print('Error deleting product image during product deletion: $e');
      }
    }
    await _firestore.collection('products').doc(productId).delete();
  }
}