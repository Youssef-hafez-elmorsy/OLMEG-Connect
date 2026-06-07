import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';
import 'package:olmeg_connect/features/orders/presentation/providers/order_provider.dart';

class SellerOrderQueueScreen extends ConsumerWidget {
  const SellerOrderQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(
        body: AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sign in required',
          message: 'Sign in with an approved seller account to review orders.',
        ),
      );
    }

    final ordersAsync = ref.watch(sellerOrdersProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Seller orders')),
      body: ordersAsync.when(
        loading: () => const AppLoadingState(label: 'Loading seller orders'),
        error: (error, _) => AppErrorState(
          title: 'Orders failed to load',
          message: '$error',
          onRetry: () => ref.invalidate(sellerOrdersProvider(user.id)),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const AppEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No seller orders yet',
              message: 'New merchant orders will appear here for fulfillment.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final order = orders[index];
              final sellerItems = order.items
                  .where((item) => item.sellerId == user.id)
                  .toList(growable: false);
              final sellerTotal = sellerItems.fold<double>(
                0,
                (subtotal, item) => subtotal + item.lineTotal,
              );
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.local_shipping_outlined),
                        title: Text('Order ${order.id.substring(0, 8)}'),
                        subtitle: Text(
                          '${_status(order.status)} - ${sellerItems.length} item${sellerItems.length == 1 ? '' : 's'}',
                        ),
                        trailing: Text(CurrencyFormatter.egp(sellerTotal)),
                      ),
                      _FulfillmentActions(order: order),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FulfillmentActions extends ConsumerWidget {
  final OrderEntity order;

  const _FulfillmentActions({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextStatuses = <OrderStatus>[
      OrderStatus.preparing,
      OrderStatus.shipped,
      OrderStatus.delivered,
      OrderStatus.cancelled,
      OrderStatus.refunded,
    ].where((status) {
      return isAllowedOrderStatusTransition(order.status, status);
    }).toList(growable: false);

    if (nextStatuses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm),
        child: Text(
          'No fulfillment actions available',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final status in nextStatuses)
          OutlinedButton.icon(
            onPressed: () => _updateStatus(context, ref, status),
            icon: Icon(_statusIcon(status)),
            label: Text(_status(status)),
          ),
        if (order.status == OrderStatus.delivered) ...[
          OutlinedButton.icon(
            onPressed: () => _setReturnStatus(context, 'seller_approved'),
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Approve return'),
          ),
          OutlinedButton.icon(
            onPressed: () => _setReturnStatus(context, 'seller_rejected'),
            icon: const Icon(Icons.block),
            label: const Text('Reject return'),
          ),
        ],
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    OrderStatus status,
  ) async {
    await ref.read(updateOrderStatusProvider((
      orderId: order.id,
      status: status,
    )).future);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked ${_status(status)}.')),
      );
    }
  }

  Future<void> _setReturnStatus(BuildContext context, String status) async {
    final request = await FirebaseFirestore.instance
        .collection('return_requests')
        .where('orderId', isEqualTo: order.id)
        .limit(1)
        .get();
    if (request.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No return request found.')),
        );
      }
      return;
    }
    await request.docs.first.reference.set({
      'status': status,
      'timeline': FieldValue.arrayUnion([
        {
          'status': status,
          'note': 'Seller reviewed the return request.',
          'createdAt': Timestamp.now(),
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return $status.')),
      );
    }
  }
}

String _status(OrderStatus status) {
  return orderStatusToString(status).replaceAllMapped(
    RegExp(r'([A-Z])'),
    (match) => ' ${match.group(0)!.toLowerCase()}',
  );
}

IconData _statusIcon(OrderStatus status) {
  switch (status) {
    case OrderStatus.pendingPayment:
      return Icons.hourglass_empty;
    case OrderStatus.paid:
      return Icons.payments_outlined;
    case OrderStatus.preparing:
      return Icons.inventory_2_outlined;
    case OrderStatus.shipped:
      return Icons.local_shipping_outlined;
    case OrderStatus.delivered:
      return Icons.check_circle_outline;
    case OrderStatus.cancelled:
      return Icons.cancel_outlined;
    case OrderStatus.refunded:
      return Icons.assignment_return_outlined;
  }
}
