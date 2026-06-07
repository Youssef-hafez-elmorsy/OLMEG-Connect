import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';
import 'package:olmeg_connect/features/orders/presentation/providers/order_provider.dart';
import 'package:olmeg_connect/features/reviews/domain/entities/review_entity.dart';
import 'package:uuid/uuid.dart';

final productReviewsProvider =
    StreamProvider.family<List<ReviewEntity>, String>((ref, productId) {
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('productId', isEqualTo: productId)
      .where('status',
          isEqualTo:
              reviewModerationStatusToString(ReviewModerationStatus.visible))
      .limit(60)
      .snapshots()
      .map((snapshot) {
    final reviews = snapshot.docs.map(_reviewFromDoc).toList();
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  });
});

final pendingReviewsProvider = StreamProvider<List<ReviewEntity>>((ref) {
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('status',
          isEqualTo: reviewModerationStatusToString(
              ReviewModerationStatus.pendingModeration))
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_reviewFromDoc).toList());
});

final completedOrderForReviewProvider = Provider.family<
    AsyncValue<OrderEntity?>, ({String buyerId, String productId})>(
  (ref, params) {
    final orders = ref.watch(buyerOrdersProvider(params.buyerId));
    return orders.whenData((items) {
      for (final order in items) {
        final hasProduct =
            order.items.any((item) => item.productId == params.productId);
        if (hasProduct && order.status == OrderStatus.delivered) {
          return order;
        }
      }
      return null;
    });
  },
);

Future<void> createProductReview({
  required WidgetRef ref,
  required String productId,
  required String sellerId,
  required String buyerId,
  required int rating,
  required String body,
  String? title,
  String? orderId,
  bool isVerifiedPurchase = false,
}) async {
  final id = const Uuid().v4();
  final now = DateTime.now();
  await FirebaseFirestore.instance.collection('reviews').doc(id).set({
    'id': id,
    'productId': productId,
    'sellerId': sellerId,
    'buyerId': buyerId,
    'orderId': orderId,
    'rating': rating,
    'title': title,
    'body': body,
    'imageUrls': <String>[],
    'isVerifiedPurchase': isVerifiedPurchase,
    'status': reviewModerationStatusToString(
      body.length > 400
          ? ReviewModerationStatus.pendingModeration
          : ReviewModerationStatus.visible,
    ),
    'createdAt': Timestamp.fromDate(now),
    'updatedAt': Timestamp.fromDate(now),
  });
  await ref
      .read(analyticsServiceProvider)
      .trackReviewSubmitted(buyerId, id)
      .catchError((_) {});
}

Future<void> updateReviewModerationStatus(
  String reviewId,
  ReviewModerationStatus status,
) async {
  await FirebaseFirestore.instance.collection('reviews').doc(reviewId).update({
    'status': reviewModerationStatusToString(status),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

ReviewEntity _reviewFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? const <String, dynamic>{};
  return ReviewEntity(
    id: doc.id,
    productId: data['productId'] as String? ?? '',
    sellerId: data['sellerId'] as String? ?? '',
    buyerId: data['buyerId'] as String? ?? '',
    orderId: data['orderId'] as String?,
    rating: (data['rating'] as num?)?.toInt() ?? 0,
    title: data['title'] as String?,
    body: data['body'] as String? ?? '',
    imageUrls: List<String>.from(data['imageUrls'] as List? ?? const []),
    isVerifiedPurchase: data['isVerifiedPurchase'] as bool? ?? false,
    status: reviewModerationStatusFromString(data['status'] as String?),
    createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
    updatedAt: _readDate(data['updatedAt']) ?? DateTime.now(),
  );
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
