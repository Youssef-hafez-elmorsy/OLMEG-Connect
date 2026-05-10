import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/notifications/domain/entities/notification_entity.dart';
import 'package:olmeg_connect/features/notifications/domain/repositories/notification_repository.dart';
import 'package:olmeg_connect/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:olmeg_connect/features/notifications/data/repositories/notification_repository_impl.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    remoteDataSource: ref.watch(notificationRemoteDataSourceProvider),
  );
});

final userNotificationsProvider =
    StreamProvider.family<List<NotificationEntity>, String>(
  (ref, userId) {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.getUserNotificationsStream(userId);
  },
);

final unreadNotificationCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUserNotificationsStream(userId).map(
        (notifications) => notifications.where((n) => !n.read).length,
      );
});

final createNotificationProvider =
    FutureProvider.family<void, NotificationEntity>((ref, notification) async {
  final repository = ref.watch(notificationRepositoryProvider);
  final result = await repository.createNotification(notification);
  result.fold(
    (failure) => throw Exception(failure.message),
    (_) => null,
  );
});

final markNotificationAsReadProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  final repository = ref.watch(notificationRepositoryProvider);
  final result = await repository.markAsRead(notificationId);
  result.fold(
    (failure) => throw Exception(failure.message),
    (_) => null,
  );
});
