import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/core/widgets/screen_performance_probe.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';
import 'package:olmeg_connect/features/orders/presentation/providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: ScreenPerformanceProbe(
        screenName: 'order_detail',
        child: orderAsync.when(
          data: (order) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Order ${order.id}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _ReceiptHeader(order: order),
              const SizedBox(height: 12),
              _Timeline(status: order.status),
              const SizedBox(height: 12),
              _Section(
                title: 'Delivery address',
                child: ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text(order.shippingAddress.fullName),
                  subtitle: Text(order.shippingAddress.formatted),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Items',
                child: Column(
                  children: [
                    for (final item in order.items)
                      ListTile(
                        title: Text(item.titleSnapshot),
                        subtitle: Text('Qty ${item.quantity}'),
                        trailing: Text(CurrencyFormatter.egp(item.lineTotal)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Receipt and payment',
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(order.payment.provider.toUpperCase()),
                  subtitle: Text(
                    [
                      paymentSummaryStatusToString(order.payment.status),
                      if (order.payment.providerPaymentId != null)
                        'ID ${order.payment.providerPaymentId}',
                      if (order.payment.failureReason != null)
                        order.payment.failureReason!,
                    ].join(' - '),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Buyer protection',
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(
                    order.payment.status == PaymentSummaryStatus.paid
                        ? 'Eligible for dispute review'
                        : 'Protection starts after payment',
                  ),
                  subtitle: const Text(
                    'Returns, refunds, and seller issues can be escalated to support with order evidence.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Total',
                child: Column(
                  children: [
                    _SummaryRow('Subtotal', order.subtotal),
                    _SummaryRow('Shipping', order.shippingFee),
                    _SummaryRow('Discount', -order.discount),
                    _SummaryRow('Tax', order.tax),
                    const Divider(),
                    _SummaryRow('Total', order.total, emphasized: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Seller invoice summary',
                child: Column(
                  children: [
                    for (final sellerId in order.sellerIds)
                      _SellerInvoiceRow(order: order, sellerId: sellerId),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _OrderActions(order: order),
            ],
          ),
          loading: () => const AppLoadingState(label: 'Loading order detail'),
          error: (error, _) => AppErrorState(
            title: 'Order failed to load',
            message: '$error',
            onRetry: () => ref.invalidate(orderProvider(orderId)),
          ),
        ),
      ),
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  final OrderEntity order;

  const _ReceiptHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buyer receipt',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Created ${_formatDate(order.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.egp(order.total),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerInvoiceRow extends StatelessWidget {
  final OrderEntity order;
  final String sellerId;

  const _SellerInvoiceRow({required this.order, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final items = order.items.where((item) => item.sellerId == sellerId);
    final total =
        items.fold<double>(0, (subtotal, item) => subtotal + item.lineTotal);

    return ListTile(
      leading: const Icon(Icons.storefront_outlined),
      title:
          Text('Seller ${sellerId.substring(0, sellerId.length.clamp(0, 8))}'),
      subtitle: Text('${items.length} item${items.length == 1 ? '' : 's'}'),
      trailing: Text(CurrencyFormatter.egp(total)),
    );
  }
}

class _OrderActions extends ConsumerWidget {
  final OrderEntity order;

  const _OrderActions({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel = order.status == OrderStatus.pendingPayment ||
        order.status == OrderStatus.paid;
    final canRequestRefund = order.status == OrderStatus.delivered ||
        order.status == OrderStatus.paid ||
        order.status == OrderStatus.preparing;
    final canRequestReturn = order.status == OrderStatus.delivered;
    final canRecoverPayment =
        order.payment.status == PaymentSummaryStatus.pending ||
            order.payment.status == PaymentSummaryStatus.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canRecoverPayment)
          OutlinedButton.icon(
            onPressed: () => _updatePayment(
              context,
              ref,
              PaymentSummaryStatus.paid,
              providerPaymentId:
                  'manual-${DateTime.now().millisecondsSinceEpoch}',
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Recover successful payment'),
          ),
        if (canCancel) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _updateStatus(context, ref, OrderStatus.cancelled),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel order'),
          ),
        ],
        if (canRequestRefund) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _updateStatus(context, ref, OrderStatus.refunded),
            icon: const Icon(Icons.assignment_return_outlined),
            label: const Text('Request refund'),
          ),
        ],
        if (canRequestReturn) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _requestReturn(context),
            icon: const Icon(Icons.assignment_return_outlined),
            label: const Text('Request return'),
          ),
        ],
        if (order.status != OrderStatus.cancelled &&
            order.status != OrderStatus.refunded) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openDispute(context),
            icon: const Icon(Icons.support_agent_outlined),
            label: const Text('Open dispute'),
          ),
        ],
      ],
    );
  }

  Future<void> _openDispute(BuildContext context) async {
    await FirebaseFirestore.instance.collection('support_tickets').add({
      'title': 'Order dispute',
      'category': 'dispute',
      'status': 'open',
      'priority':
          order.payment.status == PaymentSummaryStatus.paid ? 'high' : 'normal',
      'userId': order.buyerId,
      'orderId': order.id,
      'sellerIds': order.sellerIds,
      'summary': 'Buyer opened a dispute from order details.',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispute sent to support.')),
      );
    }
  }

  Future<void> _requestReturn(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return request'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Reason',
            helperText: 'Photos can be attached from support after submission.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final returnRef =
        await FirebaseFirestore.instance.collection('return_requests').add({
      'orderId': order.id,
      'buyerId': order.buyerId,
      'sellerIds': order.sellerIds,
      'reason': reason,
      'photoUrls': <String>[],
      'status': 'requested',
      'timeline': [
        {
          'status': 'requested',
          'note': reason,
          'createdAt': Timestamp.now(),
        }
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('support_tickets').add({
      'title': 'Return request',
      'category': 'return',
      'status': 'open',
      'priority': 'high',
      'userId': order.buyerId,
      'orderId': order.id,
      'returnRequestId': returnRef.id,
      'summary': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final sellerId in order.sellerIds) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': sellerId,
        'type': 'return_requested',
        'title': 'Return requested',
        'message': 'A buyer requested a return for order ${order.id}.',
        'relatedId': order.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return request sent.')),
      );
    }
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
    ref.invalidate(orderProvider(order.id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked ${orderStatusToString(status)}.')),
      );
    }
  }

  Future<void> _updatePayment(
    BuildContext context,
    WidgetRef ref,
    PaymentSummaryStatus status, {
    String? providerPaymentId,
  }) async {
    await ref.read(updateOrderPaymentStatusProvider((
      orderId: order.id,
      paymentStatus: status,
      providerPaymentId: providerPaymentId,
      failureReason: null,
    )).future);
    ref.invalidate(orderProvider(order.id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment status recovered.')),
      );
    }
  }
}

class _Timeline extends StatelessWidget {
  final OrderStatus status;

  const _Timeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      OrderStatus.pendingPayment,
      OrderStatus.paid,
      OrderStatus.preparing,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];
    final currentIndex = steps.indexOf(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              ListTile(
                dense: true,
                leading: Icon(
                  i <= currentIndex
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: i <= currentIndex
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                title: Text(_statusLabel(steps[i])),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasized;

  const _SummaryRow(this.label, this.value, {this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(CurrencyFormatter.egp(value), style: style),
        ],
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

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
