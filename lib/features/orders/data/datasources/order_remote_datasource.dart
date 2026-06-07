import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/orders/data/models/order_model.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';

abstract class OrderRemoteDataSource {
  Future<OrderEntity> createOrder(OrderEntity order);

  Stream<List<OrderEntity>> watchBuyerOrders(String buyerId);

  Stream<List<OrderEntity>> watchSellerOrders(String sellerId);

  Future<OrderEntity> getOrder(String orderId);

  Future<void> updateOrderStatus(String orderId, OrderStatus status);

  Future<void> updatePaymentStatus({
    required String orderId,
    required PaymentSummaryStatus paymentStatus,
    String? providerPaymentId,
    String? failureReason,
  });
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final FirebaseFirestore firestore;

  OrderRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _orders =>
      firestore.collection('orders');

  @override
  Future<OrderEntity> createOrder(OrderEntity order) async {
    try {
      final duplicate = await _orders
          .where('buyerId', isEqualTo: order.buyerId)
          .where('checkoutFingerprint', isEqualTo: order.checkoutFingerprint)
          .where('status', whereIn: [
            orderStatusToString(OrderStatus.pendingPayment),
            orderStatusToString(OrderStatus.paid),
            orderStatusToString(OrderStatus.preparing),
            orderStatusToString(OrderStatus.shipped),
          ])
          .limit(1)
          .get();

      if (duplicate.docs.isNotEmpty) {
        return OrderModel.fromFirestore(duplicate.docs.first);
      }

      final model = OrderModel.fromEntity(order);
      await _orders.doc(order.id).set(model.toMap());
      return order;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  @override
  Stream<List<OrderEntity>> watchBuyerOrders(String buyerId) {
    return _orders
        .where('buyerId', isEqualTo: buyerId)
        .limit(60)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  @override
  Stream<List<OrderEntity>> watchSellerOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .limit(60)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  @override
  Future<OrderEntity> getOrder(String orderId) async {
    try {
      final doc = await _orders.doc(orderId).get();
      if (!doc.exists) throw Exception('Order not found');
      return OrderModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final ref = _orders.doc(orderId);
      final snapshot = await ref.get();
      if (!snapshot.exists) throw Exception('Order not found');

      final order = OrderModel.fromFirestore(snapshot);
      if (!isAllowedOrderStatusTransition(order.status, status)) {
        throw Exception(
          'Cannot move order from ${orderStatusToString(order.status)} to ${orderStatusToString(status)}',
        );
      }

      await ref.update({
        'status': orderStatusToString(status),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  @override
  Future<void> updatePaymentStatus({
    required String orderId,
    required PaymentSummaryStatus paymentStatus,
    String? providerPaymentId,
    String? failureReason,
  }) async {
    try {
      final now = DateTime.now();
      await _orders.doc(orderId).update({
        'payment.status': paymentSummaryStatusToString(paymentStatus),
        'payment.providerPaymentId': providerPaymentId,
        'payment.failureReason': failureReason,
        'payment.paidAt': paymentStatus == PaymentSummaryStatus.paid
            ? Timestamp.fromDate(now)
            : null,
        'status': orderStatusToString(orderStatusForPayment(paymentStatus)),
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      throw Exception('Failed to update order payment status: $e');
    }
  }
}
