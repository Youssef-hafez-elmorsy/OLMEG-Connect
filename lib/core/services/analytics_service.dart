import 'package:olmeg_connect/features/analytics/domain/entities/analytics_event_entity.dart';
import 'package:olmeg_connect/features/analytics/data/datasources/analytics_datasource.dart';

class AnalyticsService {
  final AnalyticsDataSource dataSource;

  AnalyticsService({required this.dataSource});

  Future<void> trackProductViewed(String userId, String productId) async {
    await dataSource.trackEvent(
      AnalyticsEventEntity(
        id: '',
        userId: userId,
        eventType: 'product_viewed',
        metadata: {'productId': productId},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> trackPostCreated(String userId, String postType) async {
    await dataSource.trackEvent(
      AnalyticsEventEntity(
        id: '',
        userId: userId,
        eventType: 'post_created',
        metadata: {'postType': postType},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> trackProductPurchased(
      String userId, String productId, double amount) async {
    await dataSource.trackEvent(
      AnalyticsEventEntity(
        id: '',
        userId: userId,
        eventType: 'product_purchased',
        metadata: {'productId': productId, 'amount': amount},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> trackProductImpression(String userId, String productId) async {
    await _track(userId, 'product_impression', {'productId': productId});
  }

  Future<void> trackAddToCart(
      String userId, String productId, int quantity) async {
    await _track(
      userId,
      'add_to_cart',
      {'productId': productId, 'quantity': quantity},
    );
  }

  Future<void> trackCheckoutStarted(String userId, double total) async {
    await _track(userId, 'checkout_started', {'total': total});
  }

  Future<void> trackOrderPlaced(
      String userId, String orderId, double total) async {
    await _track(userId, 'order_placed', {'orderId': orderId, 'total': total});
  }

  Future<void> trackFavorite(String userId, String productId) async {
    await _track(userId, 'favorite', {'productId': productId});
  }

  Future<void> trackSellerAction(String userId, String action) async {
    await _track(userId, 'seller_action', {'action': action});
  }

  Future<void> trackReviewSubmitted(String userId, String reviewId) async {
    await _track(userId, 'review_submitted', {'reviewId': reviewId});
  }

  Future<void> trackUserSignUp(String userId) async {
    await dataSource.trackEvent(
      AnalyticsEventEntity(
        id: '',
        userId: userId,
        eventType: 'user_signup',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> trackUserLogin(String userId) async {
    await dataSource.trackEvent(
      AnalyticsEventEntity(
        id: '',
        userId: userId,
        eventType: 'user_login',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> trackSearchPerformed(String userId, String query) async {
    await dataSource.trackEvent(
      AnalyticsEventEntity(
        id: '',
        userId: userId,
        eventType: 'search_performed',
        metadata: {'query': query},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> trackSearchResultsViewed(
    String userId, {
    required String query,
    required int resultCount,
    required String sortBy,
  }) async {
    await _track(userId, 'search_results_viewed', {
      'query': query,
      'resultCount': resultCount,
      'sortBy': sortBy,
    });
  }

  Future<void> trackRecommendationClick(
    String userId, {
    required String productId,
    required String source,
  }) async {
    await _track(userId, 'recommendation_click', {
      'productId': productId,
      'source': source,
    });
  }

  Future<void> trackRatingSubmitted(String userId, int rating) async {
    await dataSource.trackEvent(
      AnalyticsEventEntity(
        id: '',
        userId: userId,
        eventType: 'rating_submitted',
        metadata: {'rating': rating},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    return await dataSource.getAnalytics(userId);
  }

  Future<Map<String, dynamic>> getGlobalAnalytics() async {
    return await dataSource.getGlobalAnalytics();
  }

  Future<void> _track(
    String userId,
    String eventType,
    Map<String, dynamic> metadata,
  ) async {
    await dataSource.trackEvent(
      AnalyticsEventEntity(
        id: '',
        userId: userId,
        eventType: eventType,
        metadata: metadata,
        createdAt: DateTime.now(),
      ),
    );
  }
}
