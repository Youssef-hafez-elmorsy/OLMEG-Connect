import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';
import 'package:olmeg_connect/features/orders/presentation/providers/order_provider.dart';

class PaymobPaymentResultScreen extends ConsumerWidget {
  final String? orderId;
  final String? gatewayStatus;

  const PaymobPaymentResultScreen({
    super.key,
    this.orderId,
    this.gatewayStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedStatus = gatewayStatus?.toLowerCase().trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment result')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: orderId == null || orderId!.isEmpty
            ? _ResultMessage(
                icon: Icons.schedule_outlined,
                title: 'Payment is being confirmed',
                message:
                    'Paymob returned you to Olmeg Connect. We are waiting for the secure backend webhook to confirm the final payment status.',
                actions: [
                  FilledButton.icon(
                    onPressed: () => context.go('/orders'),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View my orders'),
                  ),
                ],
              )
            : _OrderPaymentStatus(
                orderId: orderId!,
                gatewayStatus: normalizedStatus,
              ),
      ),
    );
  }
}

class _OrderPaymentStatus extends ConsumerWidget {
  final String orderId;
  final String? gatewayStatus;

  const _OrderPaymentStatus({
    required this.orderId,
    required this.gatewayStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));

    return orderAsync.when(
      loading: () => const AppLoadingState(
        label: 'Checking payment confirmation',
      ),
      error: (_, __) => AppErrorState(
        title: 'Could not load order',
        message:
            'The payment callback was received, but the order could not be loaded yet. Try opening your orders.',
        onRetry: () => ref.invalidate(orderProvider(orderId)),
      ),
      data: (order) {
        final paymentStatus = order.payment.status;
        final isPaid = paymentStatus == PaymentSummaryStatus.paid;
        final isFailed = paymentStatus == PaymentSummaryStatus.failed;

        if (isPaid) {
          return _ResultMessage(
            icon: Icons.verified_outlined,
            title: 'Payment confirmed',
            message:
                'Your Paymob payment is confirmed. Your order is now ready for seller processing.',
            actions: [
              FilledButton.icon(
                onPressed: () => context.go('/orders/$orderId'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Open receipt'),
              ),
            ],
          );
        }

        if (isFailed ||
            gatewayStatus == 'rejected' ||
            gatewayStatus == 'failed') {
          return _ResultMessage(
            icon: Icons.error_outline,
            title: 'Payment was not completed',
            message: order.payment.failureReason ??
                'You can retry payment from your order receipt.',
            actions: [
              FilledButton.icon(
                onPressed: () => context.go('/orders/$orderId'),
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Retry from order'),
              ),
            ],
          );
        }

        return _ResultMessage(
          icon: Icons.hourglass_top_outlined,
          title: 'Payment is pending confirmation',
          message:
              'Do not worry if you already paid. Paymob confirms the final result through a secure backend webhook.',
          actions: [
            FilledButton.icon(
              onPressed: () => context.go('/orders/$orderId'),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Open order'),
            ),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(orderProvider(orderId)),
              icon: const Icon(Icons.sync_outlined),
              label: const Text('Refresh status'),
            ),
          ],
        );
      },
    );
  }
}

class _ResultMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  const _ResultMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
