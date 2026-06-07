import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/widgets/product_card.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/products/presentation/providers/product_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

final userFavoritesProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('favorites')
      .where('userId', isEqualTo: user.id)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => doc['productId'] as String).toList());
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(userFavoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppColors.getBackground(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Favorites'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (favoriteIds) {
          if (favoriteIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: secondaryColor),
                  const SizedBox(height: AppSpacing.md),
                  Text('No favorites yet',
                      style: TextStyle(color: secondaryColor, fontSize: 16)),
                ],
              ),
            );
          }
          return FutureBuilder(
            future: _fetchFavoriteProducts(favoriteIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No favorites',
                    style: TextStyle(color: secondaryColor),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final product = snapshot.data![index];
                  return ProductCard(
                    product: product,
                    onFavorite: () => _toggleFavorite(
                        context, ref, product.id, product.isFavorite),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<ProductEntity>> _fetchFavoriteProducts(
      List<String> favoriteIds) async {
    if (favoriteIds.isEmpty) return [];

    final products = <ProductEntity>[];

    for (final id in favoriteIds) {
      final doc =
          await FirebaseFirestore.instance.collection('products').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        products.add(ProductEntity(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0,
          category: data['categoryName'] ?? data['category'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          sellerId: data['sellerId'] ?? '',
          sellerName: data['sellerName'] ?? '',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          city: data['location'] ?? '',
          isFavorite: true,
        ));
      }
    }
    return products;
  }

  void _toggleFavorite(BuildContext context, WidgetRef ref, String productId,
      bool isFavorite) async {
    await ref.read(favoriteNotifierProvider.notifier).toggleFavorite(productId);
    ref.invalidate(userFavoritesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                isFavorite ? 'Removed from favorites' : 'Added to favorites')),
      );
    }
  }
}
