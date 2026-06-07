import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/services/ai_marketplace_service.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/cart/presentation/providers/local_cart_provider.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';
import 'package:olmeg_connect/features/orders/presentation/providers/order_provider.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/products/presentation/providers/product_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dealProductsProvider = Provider<AsyncValue<List<ProductEntity>>>((ref) {
  final products = ref.watch(productsStreamProvider(null));
  return products.whenData((items) {
    final deals = items.where((product) => product.hasDiscount).toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return deals.take(10).toList();
  });
});

final topRatedProductsProvider =
    Provider<AsyncValue<List<ProductEntity>>>((ref) {
  final products = ref.watch(productsStreamProvider(null));
  return products.whenData((items) {
    final topRated = items
        .where((product) => product.ratingAverage > 0)
        .toList()
      ..sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
    return topRated.take(10).toList();
  });
});

final sponsoredProductsProvider =
    Provider<AsyncValue<List<ProductEntity>>>((ref) {
  final products = ref.watch(productsStreamProvider(null));
  return products.whenData((items) {
    final sponsored = items
        .where((product) => product.status != 'suspended')
        .where((product) => product.inStock)
        .toList()
      ..sort((a, b) {
        final discount = b.discountPercent.compareTo(a.discountPercent);
        return discount == 0
            ? b.ratingAverage.compareTo(a.ratingAverage)
            : discount;
      });
    return sponsored.take(8).toList();
  });
});

final relatedProductsProvider =
    Provider.family<AsyncValue<List<ProductEntity>>, ProductEntity>(
  (ref, product) {
    final products = ref.watch(productsStreamProvider(product.categoryId));
    return products.whenData((items) {
      final related = items
          .where((item) =>
              item.id != product.id &&
              (item.categoryId == product.categoryId ||
                  item.category.toLowerCase() ==
                      product.category.toLowerCase()))
          .take(8)
          .toList();
      return related;
    });
  },
);

final recentlyViewedIdsProvider = FutureProvider<List<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('recentlyViewedProducts') ?? const [];
});

final recentlyViewedProductsProvider =
    Provider<AsyncValue<List<ProductEntity>>>((ref) {
  final products = ref.watch(productsStreamProvider(null));
  final ids = ref.watch(recentlyViewedIdsProvider);
  if (products.isLoading || ids.isLoading) return const AsyncValue.loading();
  if (products.hasError) {
    return AsyncValue.error(products.error!, StackTrace.current);
  }
  if (ids.hasError) return AsyncValue.error(ids.error!, StackTrace.current);

  final productList = products.value ?? const <ProductEntity>[];
  final idList = ids.value ?? const <String>[];
  final byId = {for (final product in productList) product.id: product};
  return AsyncValue.data([
    for (final id in idList)
      if (byId[id] != null) byId[id]!,
  ]);
});

final personalizedRecommendationsProvider =
    Provider<AsyncValue<List<ProductEntity>>>((ref) {
  final products = ref.watch(productsStreamProvider(null));
  final ids = ref.watch(recentlyViewedIdsProvider);
  final user = ref.watch(authStateProvider).value;
  final favoriteIds = user == null
      ? const AsyncValue<List<String>>.data([])
      : ref.watch(_favoriteProductIdsProvider(user.id));
  final orders = user == null
      ? const AsyncValue<List<OrderEntity>>.data([])
      : ref.watch(buyerOrdersProvider(user.id));
  final cartItems = ref.watch(cartProvider);

  if (products.isLoading || ids.isLoading) return const AsyncValue.loading();
  if (favoriteIds.isLoading || orders.isLoading) {
    return const AsyncValue.loading();
  }
  if (products.hasError) {
    return AsyncValue.error(products.error!, StackTrace.current);
  }
  if (ids.hasError) return AsyncValue.error(ids.error!, StackTrace.current);
  if (favoriteIds.hasError) {
    return AsyncValue.error(favoriteIds.error!, StackTrace.current);
  }
  if (orders.hasError) {
    return AsyncValue.error(orders.error!, StackTrace.current);
  }

  final productList = products.value ?? const <ProductEntity>[];
  final viewedIds = ids.value ?? const <String>[];
  final favoriteProductIds = favoriteIds.value ?? const <String>[];
  final cartProductIds = cartItems.map((item) => item.id).toList();
  final orderedProductIds = (orders.value ?? const [])
      .expand((order) => order.items.map((item) => item.productId))
      .toList();
  final signalIds = [
    ...viewedIds,
    ...favoriteProductIds,
    ...cartProductIds,
    ...orderedProductIds,
  ];
  final signalSet = signalIds.toSet();
  final byId = {for (final product in productList) product.id: product};
  final signalProducts = [
    for (final id in signalIds)
      if (byId[id] != null) byId[id]!,
  ];

  final signalCategories = signalProducts.map((p) => p.category).toSet();
  final signalCategoryIds =
      signalProducts.map((p) => p.categoryId).whereType<String>().toSet();
  final signalSubcategories =
      signalProducts.map((p) => p.subCategoryName).whereType<String>().toSet();

  final recommendations =
      productList.where((product) => !signalSet.contains(product.id)).toList()
        ..sort((a, b) {
          final score = _personalizationScore(
            b,
            signalCategories,
            signalCategoryIds,
            signalSubcategories,
          ).compareTo(
            _personalizationScore(
              a,
              signalCategories,
              signalCategoryIds,
              signalSubcategories,
            ),
          );
          return score == 0 ? b.createdAt.compareTo(a.createdAt) : score;
        });

  return AsyncValue.data(recommendations.take(10).toList());
});

final aiMarketplaceServiceProvider = Provider<AiMarketplaceService>((ref) {
  return AiMarketplaceService();
});

final aiRecommendationsProvider =
    FutureProvider<List<ProductEntity>>((ref) async {
  final products = await ref.watch(productsStreamProvider(null).future);
  final viewedIds = await ref.watch(recentlyViewedIdsProvider.future);
  final user = ref.watch(authStateProvider).value;
  final favoriteProductIds = user == null
      ? const <String>[]
      : await ref.watch(_favoriteProductIdsProvider(user.id).future);
  final cartProductIds = ref.watch(cartProvider).map((item) => item.id);
  final signalIds = <String>{
    ...viewedIds,
    ...favoriteProductIds,
    ...cartProductIds,
  }.toList(growable: false);

  final ai = await ref
      .read(aiMarketplaceServiceProvider)
      .recommendations(signalProductIds: signalIds);
  if (ai == null || ai.productIds.isEmpty) {
    return ref.watch(personalizedRecommendationsProvider).value ??
        const <ProductEntity>[];
  }

  final byId = {for (final product in products) product.id: product};
  return [
    for (final id in ai.productIds)
      if (byId[id] != null) byId[id]!,
  ];
});

final _favoriteProductIdsProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('favorites')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => doc.data()['productId']?.toString())
          .whereType<String>()
          .toList());
});

double _personalizationScore(
  ProductEntity product,
  Set<String> categories,
  Set<String> categoryIds,
  Set<String> subcategories,
) {
  var score = 0.0;
  if (categoryIds.contains(product.categoryId)) score += 8;
  if (categories.contains(product.category)) score += 5;
  if (subcategories.contains(product.subCategoryName)) score += 4;
  if (product.hasDiscount) score += 2;
  if (product.inStock) score += 2;
  score += product.ratingAverage;
  final age = DateTime.now().difference(product.createdAt).inDays;
  if (age <= 14) score += 1;
  return score;
}

Future<void> saveRecentlyViewedProduct(String productId) async {
  final prefs = await SharedPreferences.getInstance();
  final ids = prefs.getStringList('recentlyViewedProducts') ?? <String>[];
  ids.remove(productId);
  ids.insert(0, productId);
  await prefs.setStringList('recentlyViewedProducts', ids.take(12).toList());
}
