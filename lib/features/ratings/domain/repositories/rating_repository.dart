import 'package:dartz/dartz.dart';
import 'package:olmeg_connect/core/errors/failures.dart';
import 'package:olmeg_connect/features/ratings/domain/entities/rating_entity.dart';

abstract class RatingRepository {
  Future<Either<Failure, void>> addRating(RatingEntity rating);

  Future<Either<Failure, List<RatingEntity>>> getUserRatings(String userId);

  Future<Either<Failure, double>> getAverageRating(String userId);

  Stream<List<RatingEntity>> getUserRatingsStream(String userId);
}
