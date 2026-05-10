import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:olmeg_connect/features/ratings/domain/entities/rating_entity.dart';
import 'package:olmeg_connect/features/ratings/data/models/rating_model.dart';

abstract class RatingRemoteDataSource {
  Future<void> addRating(RatingEntity rating);

  Future<List<RatingEntity>> getUserRatings(String userId);

  Future<double> getAverageRating(String userId);

  Stream<List<RatingEntity>> getUserRatingsStream(String userId);
}

class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  final FirebaseFirestore firestore;

  RatingRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> addRating(RatingEntity rating) async {
    try {
      final model = RatingModel(
        id: const Uuid().v4(),
        userId: rating.userId,
        targetUserId: rating.targetUserId,
        rating: rating.rating,
        review: rating.review,
        createdAt: DateTime.now(),
      );

      await firestore.collection('ratings').doc(model.id).set(model.toMap());
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }

  @override
  Future<List<RatingEntity>> getUserRatings(String userId) async {
    try {
      final snapshot = await firestore
          .collection('ratings')
          .where('targetUserId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get ratings: $e');
    }
  }

  @override
  Future<double> getAverageRating(String userId) async {
    try {
      final ratings = await getUserRatings(userId);
      if (ratings.isEmpty) return 0.0;

      final sum = ratings.fold<int>(0, (prev, rating) => prev + rating.rating);
      return sum / ratings.length;
    } catch (e) {
      throw Exception('Failed to calculate average rating: $e');
    }
  }

  @override
  Stream<List<RatingEntity>> getUserRatingsStream(String userId) {
    return firestore
        .collection('ratings')
        .where('targetUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RatingModel.fromMap(doc.data()))
            .toList());
  }
}
