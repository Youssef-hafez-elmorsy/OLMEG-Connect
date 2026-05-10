import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:olmeg_connect/features/analytics/domain/entities/analytics_event_entity.dart';

abstract class AnalyticsDataSource {
  Future<void> trackEvent(AnalyticsEventEntity event);

  Future<Map<String, dynamic>> getAnalytics(String userId);

  Future<Map<String, dynamic>> getGlobalAnalytics();
}

class AnalyticsDataSourceImpl implements AnalyticsDataSource {
  final FirebaseFirestore firestore;

  AnalyticsDataSourceImpl({required this.firestore});

  @override
  Future<void> trackEvent(AnalyticsEventEntity event) async {
    try {
      await firestore.collection('analytics_events').add({
        'id': const Uuid().v4(),
        'userId': event.userId,
        'eventType': event.eventType,
        'metadata': event.metadata,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to track event: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAnalytics(String userId) async {
    try {
      final snapshot = await firestore
          .collection('analytics_events')
          .where('userId', isEqualTo: userId)
          .get();

      final events = snapshot.docs;
      final eventCounts = <String, int>{};

      for (var doc in events) {
        final eventType = doc['eventType'] as String;
        eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;
      }

      return {
        'totalEvents': events.length,
        'eventCounts': eventCounts,
        'lastEvent': events.isNotEmpty
            ? DateTime.parse(events.last['createdAt'] as String)
            : null,
      };
    } catch (e) {
      throw Exception('Failed to get analytics: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getGlobalAnalytics() async {
    try {
      final snapshot = await firestore.collection('analytics_events').get();

      final events = snapshot.docs;
      final eventCounts = <String, int>{};
      final userCounts = <String, int>{};

      for (var doc in events) {
        final eventType = doc['eventType'] as String;
        final userId = doc['userId'] as String;

        eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;
        userCounts[userId] = (userCounts[userId] ?? 0) + 1;
      }

      return {
        'totalEvents': events.length,
        'totalUsers': userCounts.length,
        'eventCounts': eventCounts,
        'activeUsers': userCounts.length,
      };
    } catch (e) {
      throw Exception('Failed to get global analytics: $e');
    }
  }
}
