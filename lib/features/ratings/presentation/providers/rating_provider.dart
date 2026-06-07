import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/ratings/domain/entities/rating_entity.dart';
import 'package:olmeg_connect/features/ratings/domain/repositories/rating_repository.dart';
import 'package:olmeg_connect/features/ratings/data/datasources/rating_remote_datasource.dart';
import 'package:olmeg_connect/features/ratings/data/repositories/rating_repository_impl.dart';

final ratingRemoteDataSourceProvider = Provider<RatingRemoteDataSource>((ref) {
  return RatingRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepositoryImpl(
    remoteDataSource: ref.watch(ratingRemoteDataSourceProvider),
  );
});

final userRatingsProvider = StreamProvider.family<List<RatingEntity>, String>(
  (ref, userId) {
    final repository = ref.watch(ratingRepositoryProvider);
    return repository.getUserRatingsStream(userId);
  },
);

final averageRatingProvider = FutureProvider.family<double, String>(
  (ref, userId) async {
    final repository = ref.watch(ratingRepositoryProvider);
    final result = await repository.getAverageRating(userId);
    return result.fold(
      (failure) => 0.0,
      (ratingAverage) => ratingAverage,
    );
  },
);

final addRatingProvider =
    FutureProvider.family<void, RatingEntity>((ref, rating) async {
  final repository = ref.watch(ratingRepositoryProvider);
  final result = await repository.addRating(rating);
  result.fold(
    (failure) => throw Exception(failure.message),
    (_) => null,
  );
});
