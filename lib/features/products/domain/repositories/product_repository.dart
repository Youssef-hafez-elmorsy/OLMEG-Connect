import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Stream<List<ProductEntity>> getProducts({String? categoryId});
  Stream<List<ProductEntity>> getUserProducts(String userId);
  Future<Either<Failure, ProductEntity>> getProductById(String id);
  Future<Either<Failure, void>> addProduct({
    required ProductEntity product,
    File? imageFile,
    Uint8List? imageBytes,
  });
  Future<Either<Failure, void>> deleteProduct(String id);
}
