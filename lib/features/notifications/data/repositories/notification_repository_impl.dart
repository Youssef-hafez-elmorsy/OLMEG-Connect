import 'package:dartz/dartz.dart';
import 'package:olmeg_connect/core/errors/failures.dart';
import 'package:olmeg_connect/features/notifications/domain/entities/notification_entity.dart';
import 'package:olmeg_connect/features/notifications/domain/repositories/notification_repository.dart';
import 'package:olmeg_connect/features/notifications/data/datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> createNotification(
    NotificationEntity notification,
  ) async {
    try {
      await remoteDataSource.createNotification(notification);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getUserNotifications(
    String userId,
  ) async {
    try {
      final notifications = await remoteDataSource.getUserNotifications(userId);
      return Right(notifications);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<NotificationEntity>> getUserNotificationsStream(String userId) {
    return remoteDataSource.getUserNotificationsStream(userId);
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(String userId) async {
    try {
      final count = await remoteDataSource.getUnreadCount(userId);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
