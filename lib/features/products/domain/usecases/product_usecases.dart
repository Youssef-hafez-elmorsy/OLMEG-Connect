import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository repository;
  GetProductsUseCase(this.repository);
  Stream<List<ProductEntity>> call({String? category}) => repository.getProducts(category: category);
}

class GetUserProductsUseCase {
  final ProductRepository repository;
  GetUserProductsUseCase(this.repository);
  Stream<List<ProductEntity>> call(String userId) => repository.getUserProducts(userId);
}

class AddProductUseCase {
  final ProductRepository repository;
  AddProductUseCase(this.repository);
  Future<Either<Failure, void>> call({required ProductEntity product, required File imageFile}) =>
      repository.addProduct(product: product, imageFile: imageFile);
}

class DeleteProductUseCase {
  final ProductRepository repository;
  DeleteProductUseCase(this.repository);
  Future<Either<Failure, void>> call(String id) => repository.deleteProduct(id);
}
