import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:olmeg_connect/features/search/domain/entities/search_filter_entity.dart';
import 'package:olmeg_connect/features/search/domain/repositories/search_repository.dart';
import 'package:olmeg_connect/features/search/data/datasources/search_remote_datasource.dart';
import 'package:olmeg_connect/features/search/data/repositories/search_repository_impl.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  return SearchRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});

final searchRepositoryProvider = FutureProvider<SearchRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SearchRepositoryImpl(
    remoteDataSource: ref.watch(searchRemoteDataSourceProvider),
    sharedPreferences: prefs,
  );
});

final searchResultsProvider =
    FutureProvider.family<List<ProductEntity>, SearchFilterEntity>(
  (ref, filter) async {
    final repositoryAsync = ref.watch(searchRepositoryProvider);
    return repositoryAsync.when(
      data: (repository) async {
        final result = await repository.searchProducts(filter);
        return result.fold(
          (failure) => [],
          (products) => products,
        );
      },
      loading: () => [],
      error: (_, __) => [],
    );
  },
);

final searchHistoryProvider = FutureProvider<List<String>>((ref) async {
  final repositoryAsync = ref.watch(searchRepositoryProvider);
  return repositoryAsync.when(
    data: (repository) async {
      final result = await repository.getSearchHistory();
      return result.fold(
        (failure) => [],
        (history) => history,
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final saveSearchQueryProvider =
    FutureProvider.family<void, String>((ref, query) async {
  final repositoryAsync = ref.watch(searchRepositoryProvider);
  return repositoryAsync.when(
    data: (repository) async {
      final result = await repository.saveSearchQuery(query);
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    },
    loading: () => throw Exception('Repository loading'),
    error: (_, __) => throw Exception('Repository error'),
  );
});

final clearSearchHistoryProvider = FutureProvider<void>((ref) async {
  final repositoryAsync = ref.watch(searchRepositoryProvider);
  return repositoryAsync.when(
    data: (repository) async {
      final result = await repository.clearSearchHistory();
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    },
    loading: () => throw Exception('Repository loading'),
    error: (_, __) => throw Exception('Repository error'),
  );
});
