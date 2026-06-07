import 'package:dartz/dartz.dart';
import 'package:olmeg_connect/core/errors/failures.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';

abstract class OrderRepository {
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order);

  Stream<List<OrderEntity>> watchBuyerOrders(String buyerId);

  Stream<List<OrderEntity>> watchSellerOrders(String sellerId);

  Future<Either<Failure, OrderEntity>> getOrder(String orderId);

  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  );

  Future<Either<Failure, void>> updatePaymentStatus({
    required String orderId,
    required PaymentSummaryStatus paymentStatus,
    String? providerPaymentId,
    String? failureReason,
  });
}
