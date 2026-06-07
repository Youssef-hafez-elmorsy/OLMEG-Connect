import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';
import 'package:olmeg_connect/features/orders/presentation/providers/order_provider.dart';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(
        body: AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sign in required',
          message: 'Sign in to view your orders.',
        ),
      );
    }

    final ordersAsync = ref.watch(buyerOrdersProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Your completed marketplace orders will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text('Order ${order.id.substring(0, 8)}'),
                  subtitle: Text(
                    '${_statusLabel(order.status)} - ${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                  ),
                  trailing: Text(CurrencyFormatter.egp(order.total)),
                  onTap: () => context.push('/orders/${order.id}'),
                ),
              );
            },
          );
        },
        loading: () => const AppLoadingState(label: 'Loading orders'),
        error: (error, _) => AppErrorState(
          title: 'Orders failed to load',
          message: '$error',
          onRetry: () => ref.invalidate(buyerOrdersProvider(user.id)),
        ),
      ),
    );
  }
}

String _statusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pendingPayment:
      return 'Pending payment';
    case OrderStatus.paid:
      return 'Paid';
    case OrderStatus.preparing:
      return 'Preparing';
    case OrderStatus.shipped:
      return 'Shipped';
    case OrderStatus.delivered:
      return 'Delivered';
    case OrderStatus.cancelled:
      return 'Cancelled';
    case OrderStatus.refunded:
      return 'Refunded';
  }
}
