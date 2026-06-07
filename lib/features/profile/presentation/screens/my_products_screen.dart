import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/services/promotion_request_service.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/navigation_utils.dart';
import 'package:olmeg_connect/core/widgets/product_card.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';

class MyProductsScreen extends ConsumerWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final l10n = AppLocalizations.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(l10n.myProducts),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => closeOrGo(context),
          ),
        ),
        body: Center(child: Text(l10n.t('signInFirst'))),
      );
    }

    final productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: user.id)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(l10n.myProducts),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => closeOrGo(context),
        ),
      ),
      body: StreamBuilder(
        stream: productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('No products yet',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Tap + to add your first product',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs;
          final currentUser = ref.watch(authStateProvider).value;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data();
              final product = ProductEntity(
                id: doc.id,
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                price: (data['price'] as num?)?.toDouble() ?? 0,
                category: data['categoryName'] ?? data['category'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                sellerId: data['sellerId'] ?? '',
                sellerName: data['sellerName'] ?? '',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                categoryId: data['categoryId'],
                subCategoryId: data['subCategoryId'],
                city: data['city'] ?? data['location'] ?? '',
                isFavorite: false,
              );

              // Function to delete product
              Future<void> deleteProduct() async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Product'),
                    content: Text(
                        'Are you sure you want to delete "${product.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.error),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(doc.id)
                      .delete();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product deleted')),
                    );
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 394,
                  child: Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Product'),
                          content: Text(
                              'Are you sure you want to delete "${product.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) async {
                      await FirebaseFirestore.instance
                          .collection('products')
                          .doc(doc.id)
                          .delete();
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: AppColors.error,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ProductCard(
                            product: product,
                            onDelete: currentUser?.id == product.sellerId
                                ? deleteProduct
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.campaign_outlined),
                            label: Text(l10n.t('promoteSponsor')),
                            onPressed: currentUser == null
                                ? null
                                : () =>
                                    PromotionRequestService.showPromotionSheet(
                                      context: context,
                                      ownerId: currentUser.id,
                                      targetId: product.id,
                                      targetTitle: product.title,
                                      targetType: 'product',
                                    ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.local_offer_outlined),
                            label: Text(l10n.t('createOffer')),
                            onPressed: currentUser == null
                                ? null
                                : () =>
                                    PromotionRequestService.showPromotionSheet(
                                      context: context,
                                      ownerId: currentUser.id,
                                      targetId: product.id,
                                      targetTitle: product.title,
                                      targetType: 'product',
                                      requireDeal: true,
                                    ),
                          ),
                        ),
                      ],
                    ),
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
