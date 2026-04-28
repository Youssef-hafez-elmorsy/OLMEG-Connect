import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Stream<List<ProductModel>> getProducts({String? categoryId});
  Stream<List<ProductModel>> getUserProducts(String userId);
  Future<ProductModel> getProductById(String id);
  Future<void> addProduct({required ProductModel product, File? imageFile, Uint8List? imageBytes, String? imageExtension});
  Future<void> deleteProduct(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProductRemoteDataSourceImpl({required FirebaseFirestore firestore, required FirebaseStorage storage})
      : _firestore = firestore, _storage = storage;

  CollectionReference get _col => _firestore.collection(AppConstants.productsCollection);

  @override
  Stream<List<ProductModel>> getProducts({String? categoryId}) {
    debugPrint('[ProductRemoteDataSource] getProducts called with categoryId: $categoryId');
    Query query = _col.orderBy('createdAt', descending: true);
    
    return query.snapshots().map((s) {
      final allProducts = s.docs.map((d) => ProductModel.fromFirestore(d)).toList();
      
      if (categoryId == null || categoryId.isEmpty) {
        debugPrint('[ProductRemoteDataSource] No filter, returning ${allProducts.length} products');
        return allProducts;
      }
      
      // Filter by categoryId OR subCategoryId OR category name
      final filtered = allProducts.where((p) {
        final match = p.categoryId == categoryId || 
                    p.subCategoryId == categoryId ||
                    p.category.toLowerCase() == categoryId.toLowerCase() ||
                    (p.subCategoryName?.toLowerCase() == categoryId.toLowerCase());
        return match;
      }).toList();
      
      debugPrint('[ProductRemoteDataSource] Filtered to ${filtered.length} products for categoryId: $categoryId');
      return filtered;
    });
  }

  @override
  Stream<List<ProductModel>> getUserProducts(String userId) {
    return _col
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ProductModel.fromFirestore(d)).toList());
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final doc = await _col.doc(id).get();
    return ProductModel.fromFirestore(doc);
  }

  @override
  Future<void> addProduct({required ProductModel product, File? imageFile, Uint8List? imageBytes, String? imageExtension}) async {
    try {
      print('[Product] Uploading image for product: ${product.id}');
      final imageUrl = await _uploadImage(imageFile, imageBytes, product.id, imageExtension: imageExtension);
      print('[Product] Image uploaded successfully: $imageUrl');
      
      final updatedProduct = ProductModel(
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.price,
        category: product.category,
        imageUrl: imageUrl,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        createdAt: product.createdAt,
      );
      
      print('[Product] Saving product to Firestore');
      await _col.doc(product.id).set(updatedProduct.toFirestore());
      print('[Product] Product saved successfully');
    } on FirebaseException catch (e) {
      print('[Product] FirebaseException: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Check Firestore and Storage rules.');
      } else if (e.code == 'quota-exceeded') {
        throw Exception('Storage quota exceeded.');
      } else {
        throw Exception('Firebase error: ${e.message}');
      }
    } catch (e) {
      print('[Product] Unexpected error: $e');
      throw Exception('Failed to add product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _col.doc(id).delete();
  }

  Future<String> _uploadImage(File? file, Uint8List? bytes, String productId, {String? imageExtension}) async {
    try {
      final ext = imageExtension ?? 'jpg';
      
      // For Web: use base64 instead of Firebase Storage
      if (kIsWeb && bytes != null && bytes.isNotEmpty) {
        final base64String = base64Encode(bytes);
        return 'data:image/$ext;base64,$base64String';
      }
      
      // For Mobile/Desktop: use Firebase Storage
      final ref = _storage.ref().child('${AppConstants.productImagesPath}/$productId.$ext');
      
      String contentType;
      switch (ext.toLowerCase()) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }
      
      final metadata = SettableMetadata(contentType: contentType);
      
      UploadTask uploadTask;
      if (file != null) {
        uploadTask = ref.putFile(file);
      } else if (bytes != null && bytes.isNotEmpty) {
        uploadTask = ref.putData(bytes, metadata);
      } else {
        throw Exception('No image provided');
      }
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      print('[Product] Storage error: ${e.code} - ${e.message}');
      throw Exception('Failed to upload image: ${e.message}');
    }
  }
}