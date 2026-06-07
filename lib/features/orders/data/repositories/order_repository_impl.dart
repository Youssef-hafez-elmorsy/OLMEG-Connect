import 'package:dartz/dartz.dart';
import 'package:olmeg_connect/core/errors/failures.dart';
import 'package:olmeg_connect/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';
import 'package:olmeg_connect/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order) async {
    try {
      return Right(await remoteDataSource.createOrder(order));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<OrderEntity>> watchBuyerOrders(String buyerId) {
    return remoteDataSource.watchBuyerOrders(buyerId);
  }

  @override
  Stream<List<OrderEntity>> watchSellerOrders(String sellerId) {
    return remoteDataSource.watchSellerOrders(sellerId);
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrder(String orderId) async {
    try {
      return Right(await remoteDataSource.getOrder(orderId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    try {
      await remoteDataSource.updateOrderStatus(orderId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePaymentStatus({
    required String orderId,
    required PaymentSummaryStatus paymentStatus,
    String? providerPaymentId,
    String? failureReason,
  }) async {
    try {
      await remoteDataSource.updatePaymentStatus(
        orderId: orderId,
        paymentStatus: paymentStatus,
        providerPaymentId: providerPaymentId,
        failureReason: failureReason,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
