import 'package:dartz/dartz.dart';
import 'package:olmeg_connect/core/errors/failures.dart';
import 'package:olmeg_connect/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, void>> createNotification(NotificationEntity notification);

  Future<Either<Failure, List<NotificationEntity>>> getUserNotifications(String userId);

  Future<Either<Failure, void>> markAsRead(String notificationId);

  Stream<List<NotificationEntity>> getUserNotificationsStream(String userId);

  Future<Either<Failure, int>> getUnreadCount(String userId);
}
