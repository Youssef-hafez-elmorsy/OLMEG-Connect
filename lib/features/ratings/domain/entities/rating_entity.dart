import 'package:equatable/equatable.dart';

class RatingEntity extends Equatable {
  final String id;
  final String userId;
  final String targetUserId;
  final int rating;
  final String? review;
  final DateTime createdAt;

  const RatingEntity({
    required this.id,
    required this.userId,
    required this.targetUserId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        targetUserId,
        rating,
        review,
        createdAt,
      ];
}
