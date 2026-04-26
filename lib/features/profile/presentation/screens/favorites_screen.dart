import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/widgets/product_card.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

final userFavoritesProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('favorites')
      .where('userId', isEqualTo: user.id)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => doc['productId'] as String).toList());
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(userFavoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Favorites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (favoriteIds) {
          if (favoriteIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: AppSpacing.md),
                  Text('No favorites yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('products')
                .where('id', whereIn: favoriteIds.isNotEmpty ? favoriteIds : [''])
                .get()
                .then((snap) => snap.docs),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No favorites', style: TextStyle(color: AppColors.textSecondary)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data![index];
                  final data = doc.data();
                  final product = ProductEntity(
                    id: doc.id,
                    title: data['title'] ?? '',
                    description: data['description'] ?? '',
                    price: (data['price'] as num?)?.toDouble() ?? 0,
                    category: data['category'] ?? '',
                    imageUrl: data['imageUrl'] ?? '',
                    sellerId: data['sellerId'] ?? '',
                    sellerName: data['sellerName'] ?? '',
                    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    city: data['location'] ?? '',
                    isFavorite: true,
                  );
                  return SizedBox(
                    height: 280,
                    child: ProductCard(
                      product: product,
                      onTap: () {},
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}