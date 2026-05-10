import 'package:dartz/dartz.dart';
import 'package:olmeg_connect/core/errors/failures.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/search/domain/entities/search_filter_entity.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<ProductEntity>>> searchProducts(
    SearchFilterEntity filter,
  );

  Future<Either<Failure, List<String>>> getSearchHistory();

  Future<Either<Failure, void>> saveSearchQuery(String query);

  Future<Either<Failure, void>> clearSearchHistory();
}
