import 'package:olmeg_connect/features/ratings/domain/entities/rating_entity.dart';

class RatingModel extends RatingEntity {
  const RatingModel({
    required super.id,
    required super.userId,
    required super.targetUserId,
    required super.rating,
    super.review,
    required super.createdAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      targetUserId: map['targetUserId'] as String,
      rating: map['rating'] as int,
      review: map['review'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'targetUserId': targetUserId,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
