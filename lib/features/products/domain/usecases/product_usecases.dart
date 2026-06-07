import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository repository;
  GetProductsUseCase(this.repository);
  Stream<List<ProductEntity>> call({String? categoryId}) =>
      repository.getProducts(categoryId: categoryId);
}

class GetUserProductsUseCase {
  final ProductRepository repository;
  GetUserProductsUseCase(this.repository);
  Stream<List<ProductEntity>> call(String userId) =>
      repository.getUserProducts(userId);
}

class AddProductUseCase {
  final ProductRepository repository;
  AddProductUseCase(this.repository);
  Future<Either<Failure, void>> call({
    required ProductEntity product,
    File? imageFile,
    Uint8List? imageBytes,
  }) =>
      repository.addProduct(
          product: product, imageFile: imageFile, imageBytes: imageBytes);
}

class DeleteProductUseCase {
  final ProductRepository repository;
  DeleteProductUseCase(this.repository);
  Future<Either<Failure, void>> call(String id) => repository.deleteProduct(id);
}
