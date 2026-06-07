import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/orders/presentation/providers/order_provider.dart';
import 'package:olmeg_connect/features/products/presentation/providers/product_provider.dart';
import 'package:olmeg_connect/features/seller/presentation/providers/seller_provider.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final canAccess = ref.watch(sellerAccessProvider);
    if (user == null || !canAccess) {
      return const Scaffold(
        body: AppEmptyState(
          icon: Icons.storefront_outlined,
          title: 'Seller tools locked',
          message: 'Seller tools require an approved merchant account.',
        ),
      );
    }

    final products = ref.watch(userProductsStreamProvider(user.id));
    final orders = ref.watch(sellerOrdersProvider(user.id));
    final profile = ref.watch(sellerProfileProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Seller Center')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          profile.when(
            data: (sellerProfile) => Card(
              child: ListTile(
                leading: const Icon(Icons.storefront),
                title: Text(sellerProfile?.storeName ?? user.name),
                subtitle: Text(
                  sellerProfile == null
                      ? 'Set up storefront policies'
                      : '${sellerProfile.ratingAverage.toStringAsFixed(1)} rating - ${sellerProfile.ratingCount} reviews',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/seller/storefront'),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Listings',
                  value: products.maybeWhen(
                    data: (items) => items.length.toString(),
                    orElse: () => '...',
                  ),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  title: 'Orders',
                  value: orders.maybeWhen(
                    data: (items) => items.length.toString(),
                    orElse: () => '...',
                  ),
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          orders.maybeWhen(
            data: (sellerOrders) {
              final revenue = sellerOrders.fold<double>(
                0,
                (total, order) => total + order.total,
              );
              final delivered = sellerOrders
                  .where((order) => order.status.name == 'delivered')
                  .length;
              return Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Revenue',
                      value: CurrencyFormatter.egp(revenue),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetricCard(
                      title: 'Delivered',
                      value: delivered.toString(),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),
          orders.maybeWhen(
            data: (sellerOrders) {
              final cancelled = sellerOrders
                  .where((order) => order.status.name == 'cancelled')
                  .length;
              final cancellationRate = sellerOrders.isEmpty
                  ? 0
                  : (cancelled / sellerOrders.length * 100).round();
              final paidOut = sellerOrders
                      .where((order) => order.status.name == 'delivered')
                      .fold<double>(0, (sum, order) => sum + order.total) *
                  0.94;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payout & performance',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                          'Estimated payout: ${CurrencyFormatter.egp(paidOut)}'),
                      const Text('Marketplace fee estimate: 6%'),
                      Text('Cancellation rate: $cancellationRate%'),
                      const Text(
                          'Fulfillment speed: tracked from order status history'),
                    ],
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ToolTile(
            title: 'Inventory',
            subtitle: 'Review stock, listing status, and pricing',
            icon: Icons.inventory,
            onTap: () => context.push('/seller/inventory'),
          ),
          _ToolTile(
            title: 'Order queue',
            subtitle: 'Track incoming orders and fulfillment status',
            icon: Icons.local_shipping_outlined,
            onTap: () => context.push('/seller/orders'),
          ),
          _ToolTile(
            title: 'Storefront & policies',
            subtitle: 'Return policy, shipping methods, and store rating',
            icon: Icons.store_mall_directory_outlined,
            onTap: () => context.push('/seller/storefront'),
          ),
          _ToolTile(
            title: 'Bulk tools & settings',
            subtitle: 'CSV upload, bulk edits, restock alerts, vacation mode',
            icon: Icons.table_chart_outlined,
            onTap: () => context.push('/seller/bulk-tools'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
