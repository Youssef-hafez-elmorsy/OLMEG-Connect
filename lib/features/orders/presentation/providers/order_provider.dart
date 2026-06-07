import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/cart/domain/entities/cart_item.dart';
import 'package:olmeg_connect/features/cart/presentation/providers/local_cart_provider.dart';
import 'package:olmeg_connect/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:olmeg_connect/features/notifications/domain/entities/notification_entity.dart';
import 'package:olmeg_connect/features/notifications/presentation/providers/notification_provider.dart';
import 'package:olmeg_connect/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:olmeg_connect/features/orders/data/repositories/order_repository_impl.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';
import 'package:olmeg_connect/features/orders/domain/repositories/order_repository.dart';
import 'package:olmeg_connect/features/profile/domain/entities/address_entity.dart';
import 'package:olmeg_connect/features/profile/presentation/providers/address_provider.dart';
import 'package:olmeg_connect/features/shipping/domain/shipping_service.dart';
import 'package:uuid/uuid.dart';

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(
    remoteDataSource: ref.watch(orderRemoteDataSourceProvider),
  );
});

final buyerOrdersProvider = StreamProvider.family<List<OrderEntity>, String>(
  (ref, buyerId) =>
      ref.watch(orderRepositoryProvider).watchBuyerOrders(buyerId),
);

final sellerOrdersProvider = StreamProvider.family<List<OrderEntity>, String>(
  (ref, sellerId) =>
      ref.watch(orderRepositoryProvider).watchSellerOrders(sellerId),
);

final orderProvider = FutureProvider.family<OrderEntity, String>(
  (ref, orderId) async {
    final result = await ref.watch(orderRepositoryProvider).getOrder(orderId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (order) => order,
    );
  },
);

final createCheckoutOrderProvider =
    FutureProvider.autoDispose<OrderEntity>((ref) async {
  final user = ref.watch(authStateProvider).value;
  final address = ref.watch(defaultAddressProvider);
  final items = ref
      .watch(cartProvider)
      .where((item) => !item.savedForLater)
      .toList(growable: false);
  final totals = ref.watch(cartTotalsProvider);
  final validationMessages = ref.watch(cartValidationProvider);

  if (user == null) throw Exception('User not authenticated');
  if (address == null) throw Exception('Select a delivery address first');
  if (items.isEmpty) throw Exception('Cart is empty');
  if (validationMessages.isNotEmpty) {
    throw Exception(validationMessages.join('\n'));
  }
  final shippingQuote = ShippingService.quote(address: address, items: items);

  final order = buildOrderFromCheckout(
    buyerId: user.id,
    items: items,
    address: address,
    subtotal: totals.subtotal,
    shippingFee: shippingQuote.fee,
    tax: totals.tax,
    discount: totals.discount,
    total: totals.subtotal + shippingQuote.fee + totals.tax - totals.discount,
  );

  final result = await ref.watch(orderRepositoryProvider).createOrder(order);
  final created = result.fold(
    (failure) => throw Exception(failure.message),
    (order) => order,
  );

  ref.read(cartProvider.notifier).clear();
  await ref
      .read(analyticsServiceProvider)
      .trackOrderPlaced(user.id, created.id, created.total)
      .catchError((_) {});
  await ref.read(createNotificationProvider(NotificationEntity(
    id: const Uuid().v4(),
    userId: user.id,
    type: 'order_update',
    title: 'Order created',
    message: 'Your order ${created.id} is waiting for payment.',
    relatedId: created.id,
    createdAt: DateTime.now(),
  )).future);

  return created;
});

final updateOrderPaymentStatusProvider = FutureProvider.family<
    void,
    ({
      String orderId,
      PaymentSummaryStatus paymentStatus,
      String? providerPaymentId,
      String? failureReason,
    })>((ref, params) async {
  final repository = ref.watch(orderRepositoryProvider);
  final result = await repository.updatePaymentStatus(
    orderId: params.orderId,
    paymentStatus: params.paymentStatus,
    providerPaymentId: params.providerPaymentId,
    failureReason: params.failureReason,
  );
  result.fold(
    (failure) => throw Exception(failure.message),
    (_) => null,
  );
});

final updateOrderStatusProvider =
    FutureProvider.family<void, ({String orderId, OrderStatus status})>(
  (ref, params) async {
    final repository = ref.watch(orderRepositoryProvider);
    final result = await repository.updateOrderStatus(
      params.orderId,
      params.status,
    );
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) => null,
    );

    final refreshed = await repository.getOrder(params.orderId);
    await refreshed.fold(
      (_) async {},
      (order) async {
        await ref.read(createNotificationProvider(NotificationEntity(
          id: const Uuid().v4(),
          userId: order.buyerId,
          type: 'order_update',
          title: 'Order ${orderStatusToString(params.status)}',
          message:
              'Your order ${order.id.substring(0, 8)} is now ${orderStatusToString(params.status)}.',
          relatedId: order.id,
          createdAt: DateTime.now(),
        )).future);
        final actor = ref.read(authStateProvider).value;
        if (actor != null) {
          await ref
              .read(analyticsServiceProvider)
              .trackSellerAction(
                actor.id,
                'order_status_${orderStatusToString(params.status)}',
              )
              .catchError((_) {});
        }
      },
    );
  },
);

OrderEntity buildOrderFromCheckout({
  required String buyerId,
  required List<CartItem> items,
  required AddressEntity address,
  required double subtotal,
  required double shippingFee,
  required double tax,
  required double discount,
  required double total,
  DateTime? now,
  String? id,
}) {
  final createdAt = now ?? DateTime.now();
  final orderItems = items
      .map((item) => OrderItemEntity(
            productId: item.id,
            sellerId: item.sellerId,
            titleSnapshot: item.title,
            imageUrlSnapshot: item.imageUrl.isEmpty ? null : item.imageUrl,
            selectedVariantSnapshot: item.selectedVariant == null
                ? null
                : {'label': item.selectedVariant},
            quantity: item.quantity,
            unitPrice: item.price,
            lineTotal: item.lineTotal,
          ))
      .toList(growable: false);

  return OrderEntity(
    id: id ?? const Uuid().v4(),
    buyerId: buyerId,
    sellerIds: {
      for (final item in items) item.sellerId,
    }.toList(growable: false),
    items: orderItems,
    shippingAddress: AddressSnapshot.fromAddress(address),
    payment: const PaymentSummary(
      provider: 'paymob',
      status: PaymentSummaryStatus.pending,
    ),
    subtotal: subtotal,
    shippingFee: shippingFee,
    tax: tax,
    discount: discount,
    total: total,
    status: OrderStatus.pendingPayment,
    checkoutFingerprint: checkoutFingerprint(
      buyerId: buyerId,
      items: items,
      total: total,
    ),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

String checkoutFingerprint({
  required String buyerId,
  required List<CartItem> items,
  required double total,
}) {
  final itemKey = [...items]..sort((a, b) {
      final left = '${a.id}:${a.selectedVariant ?? ''}';
      final right = '${b.id}:${b.selectedVariant ?? ''}';
      return left.compareTo(right);
    });
  final itemsPart = itemKey
      .map(
        (item) =>
            '${item.id}:${item.selectedVariant ?? ''}:${item.quantity}:${item.price.toStringAsFixed(2)}',
      )
      .join('|');
  return '$buyerId|$itemsPart|${total.toStringAsFixed(2)}';
}
