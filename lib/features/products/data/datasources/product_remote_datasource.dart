import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Stream<List<ProductModel>> getProducts({String? category});
  Stream<List<ProductModel>> getUserProducts(String userId);
  Future<ProductModel> getProductById(String id);
  Future<void> addProduct({required ProductModel product, required File imageFile});
  Future<void> deleteProduct(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProductRemoteDataSourceImpl({required FirebaseFirestore firestore, required FirebaseStorage storage})
      : _firestore = firestore,
        _storage = storage;

  CollectionReference get _col => _firestore.collection(AppConstants.productsCollection);

  @override
  Stream<List<ProductModel>> getProducts({String? category}) {
    Query query = _col.orderBy('createdAt', descending: true);
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((s) => s.docs.map((d) => ProductModel.fromFirestore(d)).toList());
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
  Future<void> addProduct({required ProductModel product, required File imageFile}) async {
    final imageUrl = await _uploadImage(imageFile, product.id);
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
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _col.doc(id).delete();
  }

  Future<String> _uploadImage(File file, String productId) async {
    final ref = _storage.ref().child('${AppConstants.productImagesPath}/$productId.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
