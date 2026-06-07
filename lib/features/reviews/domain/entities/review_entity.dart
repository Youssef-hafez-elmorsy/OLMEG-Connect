import 'package:equatable/equatable.dart';

enum ReviewModerationStatus {
  visible,
  pendingModeration,
  hidden,
  removed,
}

String reviewModerationStatusToString(ReviewModerationStatus status) =>
    status.name;

ReviewModerationStatus reviewModerationStatusFromString(String? value) {
  return ReviewModerationStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => ReviewModerationStatus.visible,
  );
}

class ReviewEntity extends Equatable {
  final String id;
  final String productId;
  final String sellerId;
  final String buyerId;
  final String? orderId;
  final int rating;
  final String? title;
  final String body;
  final List<String> imageUrls;
  final bool isVerifiedPurchase;
  final ReviewModerationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewEntity({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.buyerId,
    this.orderId,
    required this.rating,
    this.title,
    required this.body,
    this.imageUrls = const [],
    this.isVerifiedPurchase = false,
    this.status = ReviewModerationStatus.visible,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        sellerId,
        buyerId,
        orderId,
        rating,
        title,
        body,
        imageUrls,
        isVerifiedPurchase,
        status,
        createdAt,
        updatedAt,
      ];
}
