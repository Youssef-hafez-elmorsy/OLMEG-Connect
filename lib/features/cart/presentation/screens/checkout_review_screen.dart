import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/buyer_experience_widgets.dart';
import 'package:olmeg_connect/core/widgets/screen_performance_probe.dart';
import 'package:olmeg_connect/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/cart/presentation/providers/local_cart_provider.dart';
import 'package:olmeg_connect/features/orders/presentation/providers/order_provider.dart';
import 'package:olmeg_connect/features/payments/presentation/providers/payment_provider.dart';
import 'package:olmeg_connect/features/payments/presentation/services/paymob_checkout_launcher.dart';
import 'package:olmeg_connect/features/profile/presentation/providers/address_provider.dart';
import 'package:olmeg_connect/features/shipping/domain/shipping_service.dart';

class CheckoutReviewScreen extends ConsumerWidget {
  const CheckoutReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider).where((item) => !item.savedForLater);
    final totals = ref.watch(cartTotalsProvider);
    final defaultAddress = ref.watch(defaultAddressProvider);
    final validationMessages = ref.watch(cartValidationProvider);
    final activeItems = items.toList(growable: false);
    final shippingQuote = defaultAddress == null
        ? null
        : ShippingService.quote(address: defaultAddress, items: activeItems);
    final canConfirm = items.isNotEmpty &&
        defaultAddress != null &&
        validationMessages.isEmpty;
    final disabledReason = _checkoutBlockedReason(
      hasItems: items.isNotEmpty,
      hasAddress: defaultAddress != null,
      validationMessages: validationMessages,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Review checkout')),
      body: ScreenPerformanceProbe(
        screenName: 'checkout_review',
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BuyerHeroPanel(
              eyebrow: canConfirm ? 'Ready to order' : 'Checkout review',
              title: canConfirm
                  ? 'Everything is ready'
                  : 'Complete the missing checkout step',
              message: canConfirm
                  ? 'Review delivery, payment, and totals before creating your pending-payment order.'
                  : disabledReason ??
                      'Add items and an address to continue checkout.',
              icon: canConfirm
                  ? Icons.verified_user_outlined
                  : Icons.info_outline,
              stats: [
                BuyerTrustChip(
                  icon: Icons.shopping_bag_outlined,
                  label:
                      '${activeItems.length} item${activeItems.length == 1 ? '' : 's'}',
                ),
                const BuyerTrustChip(
                  icon: Icons.payments_outlined,
                  label: 'Pending payment',
                  color: AppColors.warning,
                ),
                if (shippingQuote != null)
                  BuyerTrustChip(
                    icon: Icons.local_shipping_outlined,
                    label: '${shippingQuote.shipmentCount} shipment',
                    color: AppColors.success,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Delivery address',
              child: defaultAddress == null
                  ? ListTile(
                      leading: const Icon(Icons.add_location_alt_outlined),
                      title: const Text('Add delivery address'),
                      onTap: () => context.push('/addresses'),
                    )
                  : ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: Text(defaultAddress.fullName),
                      subtitle: Text(defaultAddress.formatted),
                      trailing: TextButton(
                        onPressed: () => context.push('/addresses'),
                        child: const Text('Change'),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Delivery option',
              child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Approved merchant delivery'),
                subtitle: Text(
                  shippingQuote == null
                      ? 'Add an address to calculate delivery.'
                      : '${shippingQuote.shipmentCount} shipment${shippingQuote.shipmentCount == 1 ? '' : 's'} - zone ${shippingQuote.zone} - ETA ${_formatDate(shippingQuote.estimatedDeliveryDate)}. Phone confirmation required.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _Section(
              title: 'Payment method',
              child: ListTile(
                leading: Icon(Icons.payments_outlined),
                title: Text('Paymob'),
                subtitle: Text(
                  'Secure card and wallet checkout. Paymob confirms the final status through backend webhooks.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Items',
              child: Column(
                children: [
                  for (final item in items)
                    ListTile(
                      title: Text(item.title),
                      subtitle: Text('Qty ${item.quantity}'),
                      trailing: Text(CurrencyFormatter.egp(item.lineTotal)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Order summary',
              child: Column(
                children: [
                  _SummaryRow('Subtotal', totals.subtotal),
                  _SummaryRow(
                      'Shipping', shippingQuote?.fee ?? totals.shipping),
                  _SummaryRow('Discount', -totals.discount),
                  _SummaryRow('Tax', totals.tax),
                  const Divider(),
                  _SummaryRow(
                    'Total',
                    totals.subtotal +
                        (shippingQuote?.fee ?? totals.shipping) +
                        totals.tax -
                        totals.discount,
                    emphasized: true,
                  ),
                ],
              ),
            ),
            if (validationMessages.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final message in validationMessages)
                Text(message,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            _PlaceOrderButton(
              canConfirm: canConfirm,
              disabledReason: disabledReason,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceOrderButton extends ConsumerStatefulWidget {
  final bool canConfirm;
  final String? disabledReason;

  const _PlaceOrderButton({
    required this.canConfirm,
    required this.disabledReason,
  });

  @override
  ConsumerState<_PlaceOrderButton> createState() => _PlaceOrderButtonState();
}

class _PlaceOrderButtonState extends ConsumerState<_PlaceOrderButton> {
  bool _isPlacing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: widget.canConfirm && !_isPlacing ? _placeOrder : null,
          icon: _isPlacing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_outline),
          label: Text(_isPlacing
              ? 'Creating pending-payment order...'
              : 'Create order and continue to payment'),
        ),
        if (!widget.canConfirm && widget.disabledReason != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.disabledReason!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    try {
      final user = ref.read(authStateProvider).value;
      final total = ref.read(cartTotalsProvider).total;
      if (user != null) {
        await ref
            .read(analyticsServiceProvider)
            .trackCheckoutStarted(user.id, total)
            .catchError((_) {});
      }
      final order = await ref.refresh(createCheckoutOrderProvider.future);
      final checkout = await ref.refresh(
        startPaymobCheckoutProvider(order.id).future,
      );
      await const PaymobCheckoutLauncher().launch(checkout);
      if (mounted) {
        context.go('/orders/${order.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }
}

String? _checkoutBlockedReason({
  required bool hasItems,
  required bool hasAddress,
  required List<String> validationMessages,
}) {
  if (!hasItems) return 'Add at least one available item to continue.';
  if (!hasAddress) return 'Add a delivery address before creating the order.';
  if (validationMessages.isNotEmpty) {
    return 'Fix cart availability before creating the order.';
  }
  return null;
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: isDark ? AppColors.divider : AppColors.dividerLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BuyerSectionHeader(title: title),
            const SizedBox(height: AppSpacing.sm),
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

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
