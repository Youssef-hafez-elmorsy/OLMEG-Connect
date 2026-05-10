import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/theme/app_theme_helper.dart';
import 'package:olmeg_connect/core/widgets/loading_widget.dart';
import 'package:olmeg_connect/features/products/domain/entities/category_entity.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/products/presentation/providers/category_provider.dart';
import 'package:olmeg_connect/features/products/presentation/providers/product_provider.dart';
import 'package:olmeg_connect/features/products/presentation/widgets/product_card.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/profile/presentation/screens/favorites_screen.dart';

class SelectedHomeCategoryNotifier extends Notifier<CategoryEntity?> {
  @override
  CategoryEntity? build() => null;

  void select(CategoryEntity? category) {
    state = category;
  }
}

final selectedHomeCategoryProvider =
    NotifierProvider<SelectedHomeCategoryNotifier, CategoryEntity?>(() {
  return SelectedHomeCategoryNotifier();
});

class SelectedHomeSubcategoryNotifier extends Notifier<SubcategoryEntity?> {
  @override
  SubcategoryEntity? build() => null;

  void select(SubcategoryEntity? subcategory) {
    state = subcategory;
  }
}

final selectedHomeSubcategoryProvider =
    NotifierProvider<SelectedHomeSubcategoryNotifier, SubcategoryEntity?>(() {
  return SelectedHomeSubcategoryNotifier();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedHomeCategoryProvider);
    final selectedSubcategory = ref.watch(selectedHomeSubcategoryProvider);
    final user = ref.watch(authStateProvider).value;
    final l10n = AppLocalizations.of(context);

    // Filter by category AND subcategory
    final filterId = selectedSubcategory?.id ?? selectedCategory?.id ?? '';
    final productsAsync =
        ref.watch(productsStreamProvider(filterId.isEmpty ? null : filterId));

    return Scaffold(
      backgroundColor: AppThemeHelper.background(context),
      appBar: AppBar(
        backgroundColor: AppThemeHelper.background(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.hello(user?.name.split(' ').first ?? l10n.there),
              style: TextStyle(
                fontSize: 12,
                color: AppThemeHelper.textSecondary(context),
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              'Olmeg Connect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppThemeHelper.textPrimary(context),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined,
                color: AppThemeHelper.textPrimary(context)),
            onPressed: () => context.push('/cart'),
          ),
          IconButton(
            icon:
                Icon(Icons.refresh, color: AppThemeHelper.textPrimary(context)),
            onPressed: () => ref.invalidate(
                productsStreamProvider(filterId.isEmpty ? null : filterId)),
          ),
          IconButton(
            icon:
                Icon(Icons.search, color: AppThemeHelper.textPrimary(context)),
            onPressed: () => context.push('/advanced-search'),
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: AppThemeHelper.textPrimary(context)),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          _CategoryFilter(),
          const SizedBox(height: AppSpacing.sm),
          _SubcategoryFilter(),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: productsAsync.when(
              loading: () => const ShimmerGrid(),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () async =>
                    await ref.refresh(productsStreamProvider(filterId).future),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyState(
                      category: selectedSubcategory?.name ??
                          selectedCategory?.name ??
                          'all');
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    // ignore: unused_result
                    ref.refresh(productsStreamProvider(filterId).future);
                  },
                  color: AppColors.primary,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) =>
                        _ProductCardWrapper(product: products[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCardWrapper extends ConsumerWidget {
  final ProductEntity product;

  const _ProductCardWrapper({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).value;
    final isOwner = user?.id == product.sellerId;

    return ProductCard(
      product: product,
      onDelete: isOwner
          ? () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.deleteProduct),
                  content: Text(l10n.deleteProductQuestion(product.title)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel)),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.delete,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(product.id)
                    .delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.productDeleted)));
                }
              }
            }
          : null,
      onFavorite: () async {
        final user = ref.read(authStateProvider).value;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.signInForFavorites)),
          );
          return;
        }
        await ref
            .read(favoriteNotifierProvider.notifier)
            .toggleFavorite(product.id);
        ref.invalidate(userFavoritesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(product.isFavorite
                ? l10n.removedFromFavorites
                : l10n.addedToFavorites),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(selectedHomeCategoryProvider);

    return SizedBox(
      height: 48,
      child: categoriesAsync.when(
        loading: () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, __) => Container(
            width: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
        ),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(l10n.failedToLoad,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        data: (categories) {
          // Remove ALL duplicates by name (case-insensitive)
          final seenNames = <String>{};
          final uniqueCategories = <CategoryEntity>[];
          for (final cat in categories) {
            final nameLower = cat.name.toLowerCase().trim();
            if (!seenNames.contains(nameLower)) {
              seenNames.add(nameLower);
              uniqueCategories.add(cat);
            }
          }
          // Sort alphabetically but put "Used" (Old) first, then "New", then others
          uniqueCategories.sort((a, b) {
            if (a.name.toLowerCase() == 'used') return -1;
            if (b.name.toLowerCase() == 'used') return 1;
            if (a.name.toLowerCase() == 'new') return -1;
            if (b.name.toLowerCase() == 'new') return 1;
            return a.name.compareTo(b.name);
          });
          final items = [
            CategoryEntity(id: '', name: l10n.all),
            ...uniqueCategories
          ];

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = items[index];
              final isSelected = category.id == selectedCategory?.id ||
                  (selectedCategory == null && category.id == '');
              final displayLabel =
                  category.name.isEmpty ? l10n.all : category.name;

              return GestureDetector(
                onTap: () {
                  ref
                      .read(selectedHomeCategoryProvider.notifier)
                      .select(category);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    displayLabel,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
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

class _SubcategoryFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedCategory = ref.watch(selectedHomeCategoryProvider);
    final selectedSubcategory = ref.watch(selectedHomeSubcategoryProvider);

    // Only show subcategories if a category is selected
    if (selectedCategory == null) {
      return const SizedBox.shrink();
    }

    final subcategoriesAsync =
        ref.watch(subcategoriesStreamProvider(selectedCategory.id));

    return SizedBox(
      height: 36,
      child: subcategoriesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => const SizedBox.shrink(),
        data: (subcategories) {
          if (subcategories.isEmpty) {
            return const SizedBox.shrink();
          }

          // Remove ALL duplicate subcategories by name (case-insensitive)
          final seenNames = <String>{};
          final uniqueSubcategories = <SubcategoryEntity>[];
          for (final sub in subcategories) {
            final nameLower = sub.name.toLowerCase().trim();
            if (!seenNames.contains(nameLower)) {
              seenNames.add(nameLower);
              uniqueSubcategories.add(sub);
            }
          }
          uniqueSubcategories.sort((a, b) => a.name.compareTo(b.name));

          final items = [
            SubcategoryEntity(id: '', name: l10n.all, categoryId: ''),
            ...uniqueSubcategories
          ];

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final sub = items[index];
              final isSelected = sub.id == selectedSubcategory?.id ||
                  (selectedSubcategory == null && sub.id == '');
              final label = sub.name;

              return GestureDetector(
                onTap: () {
                  ref
                      .read(selectedHomeSubcategoryProvider.notifier)
                      .select(sub);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
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

class _EmptyState extends StatelessWidget {
  final String category;

  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.noProductsFound,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            category == 'all' || category == l10n.all || category.isEmpty
                ? l10n.firstProductPrompt
                : l10n.noCategoryProducts(category),
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
