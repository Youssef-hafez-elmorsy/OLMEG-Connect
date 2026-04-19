import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Stream<List<ProductEntity>> getProducts({String? category});
  Stream<List<ProductEntity>> getUserProducts(String userId);
  Future<Either<Failure, ProductEntity>> getProductById(String id);
  Future<Either<Failure, void>> addProduct({required ProductEntity product, required File imageFile});
  Future<Either<Failure, void>> deleteProduct(String id);
}
