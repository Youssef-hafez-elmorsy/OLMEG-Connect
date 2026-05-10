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

  Future<void> trackProductPurchased(String userId, String productId, double amount) async {
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
}
