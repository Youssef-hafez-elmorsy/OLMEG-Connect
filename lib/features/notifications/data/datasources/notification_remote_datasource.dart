import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:olmeg_connect/features/notifications/domain/entities/notification_entity.dart';
import 'package:olmeg_connect/features/notifications/data/models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<void> createNotification(NotificationEntity notification);

  Future<List<NotificationEntity>> getUserNotifications(String userId);

  Future<void> markAsRead(String notificationId);

  Stream<List<NotificationEntity>> getUserNotificationsStream(String userId);

  Future<int> getUnreadCount(String userId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore firestore;

  NotificationRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> createNotification(NotificationEntity notification) async {
    try {
      final model = NotificationModel(
        id: const Uuid().v4(),
        userId: notification.userId,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        relatedId: notification.relatedId,
        read: false,
        createdAt: DateTime.now(),
      );

      await firestore
          .collection('notifications')
          .doc(model.id)
          .set(model.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  @override
  Future<List<NotificationEntity>> getUserNotifications(String userId) async {
    try {
      final snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final doc =
          await firestore.collection('notifications').doc(notificationId).get();
      if (doc.exists) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Stream<List<NotificationEntity>> getUserNotificationsStream(String userId) {
    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.take(50).toList();
    });
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['read'] == false || data['read'] == null) {
          count++;
        }
      }
      return count;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }
}
