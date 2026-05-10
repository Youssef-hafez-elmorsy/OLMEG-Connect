import 'package:dartz/dartz.dart';
import 'package:olmeg_connect/core/errors/failures.dart';
import 'package:olmeg_connect/features/ratings/domain/entities/rating_entity.dart';
import 'package:olmeg_connect/features/ratings/domain/repositories/rating_repository.dart';
import 'package:olmeg_connect/features/ratings/data/datasources/rating_remote_datasource.dart';

class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDataSource remoteDataSource;

  RatingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> addRating(RatingEntity rating) async {
    try {
      await remoteDataSource.addRating(rating);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RatingEntity>>> getUserRatings(
    String userId,
  ) async {
    try {
      final ratings = await remoteDataSource.getUserRatings(userId);
      return Right(ratings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getAverageRating(String userId) async {
    try {
      final average = await remoteDataSource.getAverageRating(userId);
      return Right(average);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<RatingEntity>> getUserRatingsStream(String userId) {
    return remoteDataSource.getUserRatingsStream(userId);
  }
}
