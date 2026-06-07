import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Stream<List<ProductModel>> getProducts({String? categoryId});
  Stream<List<ProductModel>> getUserProducts(String userId);
  Future<ProductModel> getProductById(String id);
  Future<void> addProduct(
      {required ProductModel product,
      File? imageFile,
      Uint8List? imageBytes,
      String? imageExtension});
  Future<void> deleteProduct(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  static const int productListLimit = 80;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProductRemoteDataSourceImpl(
      {required FirebaseFirestore firestore, required FirebaseStorage storage})
      : _firestore = firestore,
        _storage = storage;

  CollectionReference get _col =>
      _firestore.collection(AppConstants.productsCollection);

  @override
  Stream<List<ProductModel>> getProducts({String? categoryId}) {
    final filterId = categoryId?.trim();
    if (filterId != null && filterId.isNotEmpty) {
      return _getFilteredProducts(filterId);
    }

    final query =
        _col.orderBy('createdAt', descending: true).limit(productListLimit);

    return query.snapshots().map((s) {
      final allProducts = s.docs
          .where((d) {
            final data = d.data() as Map<String, dynamic>;
            return _isPublicProduct(data);
          })
          .map((d) => ProductModel.fromFirestore(d))
          .toList();

      return allProducts;
    });
  }

  Stream<List<ProductModel>> _getFilteredProducts(String filterId) {
    final controller = StreamController<List<ProductModel>>();
    final latest = <int, List<ProductModel>>{};
    final queries = [
      _fieldQuery('categoryId', filterId),
      _fieldQuery('subCategoryId', filterId),
      _fieldQuery('categoryName', filterId),
      _fieldQuery('category', filterId),
    ];

    late final List<StreamSubscription<QuerySnapshot>> subscriptions;
    void emitMerged() {
      final byId = <String, ProductModel>{};
      for (final products in latest.values) {
        for (final product in products) {
          byId[product.id] = product;
        }
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(merged.take(productListLimit).toList());
    }

    subscriptions = [
      for (var i = 0; i < queries.length; i++)
        queries[i].snapshots().listen((snapshot) {
          latest[i] = snapshot.docs
              .where((doc) => _isPublicProduct(
                    doc.data() as Map<String, dynamic>,
                  ))
              .map((doc) => ProductModel.fromFirestore(doc))
              .where((product) => _matchesFilter(product, filterId))
              .toList();
          emitMerged();
        }, onError: controller.addError),
    ];

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  Query _fieldQuery(String field, String value) {
    return _col
        .where(field, isEqualTo: value)
        .orderBy('createdAt', descending: true)
        .limit(productListLimit);
  }

  bool _isPublicProduct(Map<String, dynamic> data) {
    final status = data['moderationStatus'] as String?;
    final publishStatus = data['publishStatus'] as String?;
    final listingStatus = data['status'] as String?;
    return (status == null || status == 'approved') &&
        publishStatus != 'draft' &&
        publishStatus != 'scheduled' &&
        listingStatus != 'draft' &&
        listingStatus != 'scheduled';
  }

  bool _matchesFilter(ProductModel product, String filterId) {
    final normalizedFilter = filterId.toLowerCase();
    return product.categoryId == filterId ||
        product.subCategoryId == filterId ||
        product.category.toLowerCase() == normalizedFilter ||
        product.subCategoryName?.toLowerCase() == normalizedFilter;
  }

  @override
  Stream<List<ProductModel>> getUserProducts(String userId) {
    return _col
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(productListLimit)
        .snapshots()
        .map((s) => s.docs.map((d) => ProductModel.fromFirestore(d)).toList());
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final doc = await _col.doc(id).get();
    return ProductModel.fromFirestore(doc);
  }

  @override
  Future<void> addProduct(
      {required ProductModel product,
      File? imageFile,
      Uint8List? imageBytes,
      String? imageExtension}) async {
    try {
      final imageUrl = await _uploadImage(imageFile, imageBytes, product.id,
          sellerId: product.sellerId, imageExtension: imageExtension);

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

      await _col.doc(product.id).set(updatedProduct.toFirestore());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Check Firestore and Storage rules.');
      } else if (e.code == 'quota-exceeded') {
        throw Exception('Storage quota exceeded.');
      } else {
        throw Exception('Firebase error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _col.doc(id).delete();
  }

  Future<String> _uploadImage(File? file, Uint8List? bytes, String productId,
      {required String sellerId, String? imageExtension}) async {
    try {
      final ext = imageExtension ?? 'jpg';

      // For Web: use base64 instead of Firebase Storage
      if (kIsWeb && bytes != null && bytes.isNotEmpty) {
        final base64String = base64Encode(bytes);
        return 'data:image/$ext;base64,$base64String';
      }

      // For Mobile/Desktop: use Firebase Storage
      final ref = _storage
          .ref()
          .child('${AppConstants.productImagesPath}/$sellerId/$productId.$ext');

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

      final metadata = SettableMetadata(
        contentType: contentType,
        cacheControl: 'public,max-age=31536000,immutable',
      );

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
      throw Exception('Failed to upload image: ${e.message}');
    }
  }
}
