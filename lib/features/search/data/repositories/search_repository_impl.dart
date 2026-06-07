import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:olmeg_connect/core/errors/failures.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/search/domain/entities/search_filter_entity.dart';
import 'package:olmeg_connect/features/search/domain/repositories/search_repository.dart';
import 'package:olmeg_connect/features/search/data/datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  SearchRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  @override
  Future<Either<Failure, List<ProductEntity>>> searchProducts(
    SearchFilterEntity filter,
  ) async {
    try {
      final result = await remoteDataSource.searchProducts(filter);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSearchHistory() async {
    try {
      final history = sharedPreferences.getStringList('search_history') ?? [];
      return Right(history);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSearchQuery(String query) async {
    try {
      final history = sharedPreferences.getStringList('search_history') ?? [];
      history.remove(query);
      history.insert(0, query);
      if (history.length > 10) {
        history.removeLast();
      }
      await sharedPreferences.setStringList('search_history', history);
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearSearchHistory() async {
    try {
      await sharedPreferences.remove('search_history');
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
