import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _dataSource;
  ProductRepositoryImpl(this._dataSource);

  @override
  Stream<List<ProductEntity>> getProducts({String? category}) =>
      _dataSource.getProducts(category: category);

  @override
  Stream<List<ProductEntity>> getUserProducts(String userId) =>
      _dataSource.getUserProducts(userId);

  @override
  Future<Either<Failure, ProductEntity>> getProductById(String id) async {
    try {
      final product = await _dataSource.getProductById(id);
      return Right(product);
    } catch (_) {
      return const Left(ServerFailure('Failed to load product.'));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct({required ProductEntity product, required File imageFile}) async {
    try {
      final model = ProductModel(
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.price,
        category: product.category,
        imageUrl: product.imageUrl,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        createdAt: product.createdAt,
      );
      await _dataSource.addProduct(product: model, imageFile: imageFile);
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure('Failed to add product.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await _dataSource.deleteProduct(id);
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure('Failed to delete product.'));
    }
  }
}
