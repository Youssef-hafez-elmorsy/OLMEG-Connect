import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/buyer_experience_widgets.dart';
import 'package:olmeg_connect/features/cart/domain/entities/cart_item.dart';
import 'package:olmeg_connect/features/cart/presentation/providers/local_cart_provider.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/products/presentation/providers/product_discovery_provider.dart';
import 'package:olmeg_connect/features/products/presentation/widgets/product_card.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final totals = ref.watch(cartTotalsProvider);
    final validationMessages = ref.watch(cartValidationProvider);
    final conflictMessages = ref.watch(cartConflictProvider);
    final recommendations = ref.watch(topRatedProductsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final activeItems = cartItems.where((item) => !item.savedForLater).toList();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('myCart')),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(cartProvider.notifier).clear(),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: BuyerHeroPanel(
                  eyebrow: l10n.t('cart'),
                  title: l10n.t('cartEmptyTitle'),
                  message: l10n.t('cartEmptyMessage'),
                  icon: Icons.shopping_cart_outlined,
                  action: FilledButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.storefront_outlined),
                    label: Text(l10n.t('browseMarketplace')),
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index == cartItems.length) {
                        return _CartRecommendations(products: recommendations);
                      }
                      final item = cartItems[index];
                      return _CartItemCard(
                        item: item,
                        onRemove: () =>
                            ref.read(cartProvider.notifier).removeItem(item.id),
                        onQuantityChanged: (q) => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.id, q),
                        onSaveForLater: () => ref
                            .read(cartProvider.notifier)
                            .toggleSaveForLater(item.id),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BuyerSectionHeader(
                          title: l10n.t('cartSummary'),
                          subtitle: l10n.activeItemsReady(activeItems.length),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.t('subtotal')),
                            Text(CurrencyFormatter.egp(totals.subtotal),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (validationMessages.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (final message in validationMessages)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                message,
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                        conflictMessages.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (messages) => Column(
                            children: [
                              for (final message in messages)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      color: colorScheme.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: activeItems.isEmpty ||
                                    validationMessages.isNotEmpty
                                ? null
                                : () => context.push('/checkout'),
                            icon: const Icon(Icons.lock_outline),
                            label: Text(l10n.t('reviewCheckoutSecurely')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartRecommendations extends StatelessWidget {
  final AsyncValue<List<ProductEntity>> products;

  const _CartRecommendations({required this.products});

  @override
  Widget build(BuildContext context) {
    return products.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).t('recommendedAddOns'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 245,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.take(6).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: 168,
                    child: ProductCard(product: items[index]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;
  final VoidCallback onSaveForLater;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onSaveForLater,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.isNotEmpty
                  ? _CartImage(url: item.imageUrl)
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(l10n.sellerName(item.sellerName),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(CurrencyFormatter.egp(item.price),
                      style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                  if (item.selectedVariant != null) ...[
                    const SizedBox(height: 4),
                    Text(l10n.variantName(item.selectedVariant!),
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                  if (!item.isAvailable || !item.hasValidQuantity) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.isAvailable
                          ? l10n.onlyAvailable(item.stockQuantity)
                          : l10n.t('outOfStock'),
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => onQuantityChanged(item.quantity - 1),
                        iconSize: 20,
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: item.quantity >= item.stockQuantity
                            ? null
                            : () => onQuantityChanged(item.quantity + 1),
                        iconSize: 20,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onSaveForLater,
                      child: Text(
                        item.savedForLater
                            ? l10n.t('moveToCart')
                            : l10n.t('saveForLater'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartImage extends StatelessWidget {
  final String url;

  const _CartImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('data:image')) {
      final bytes = Uint8List.fromList(base64Decode(url.split(',').last));
      return Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover);
    }

    return Image.network(
      url,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 80,
        height: 80,
        color: Colors.grey[300],
        child: const Icon(Icons.image),
      ),
    );
  }
}
