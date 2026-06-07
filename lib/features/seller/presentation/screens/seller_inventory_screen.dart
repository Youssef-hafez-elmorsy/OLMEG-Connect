import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/products/presentation/providers/product_provider.dart';

class SellerInventoryScreen extends ConsumerWidget {
  const SellerInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(
        body: AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sign in required',
          message:
              'Sign in with an approved seller account to manage listings.',
        ),
      );
    }

    final productsAsync = ref.watch(userProductsStreamProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Seller inventory')),
      body: productsAsync.when(
        loading: () => const AppLoadingState(label: 'Loading inventory'),
        error: (error, _) => AppErrorState(
          title: 'Inventory failed to load',
          message: '$error',
          onRetry: () => ref.invalidate(userProductsStreamProvider(user.id)),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No listings yet',
              message: 'Published products will appear here for stock review.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(product.title),
                  subtitle: Text(
                    '${product.stockQuantity} in stock - ${product.status}',
                  ),
                  trailing: Text(CurrencyFormatter.egp(product.price)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
