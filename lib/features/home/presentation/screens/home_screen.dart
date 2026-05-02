import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

final selectedHomeCategoryProvider = NotifierProvider<SelectedHomeCategoryNotifier, CategoryEntity?>(() {
  return SelectedHomeCategoryNotifier();
});

class SelectedHomeSubcategoryNotifier extends Notifier<SubcategoryEntity?> {
  @override
  SubcategoryEntity? build() => null;

  void select(SubcategoryEntity? subcategory) {
    state = subcategory;
  }
}

final selectedHomeSubcategoryProvider = NotifierProvider<SelectedHomeSubcategoryNotifier, SubcategoryEntity?>(() {
  return SelectedHomeSubcategoryNotifier();
});


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedHomeCategoryProvider);
    final selectedSubcategory = ref.watch(selectedHomeSubcategoryProvider);
    final user = ref.watch(authStateProvider).value;

    // Filter by category AND subcategory
    final filterId = selectedSubcategory?.id ?? selectedCategory?.id ?? '';
    final productsAsync = ref.watch(productsStreamProvider(filterId.isEmpty ? null : filterId));



    return Scaffold(
      backgroundColor: AppThemeHelper.background(context),
      appBar: AppBar(
        backgroundColor: AppThemeHelper.background(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.name.split(' ').first ?? 'there'}',
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
            icon: Icon(Icons.refresh, color: AppThemeHelper.textPrimary(context)),
            onPressed: () => ref.invalidate(productsStreamProvider(filterId.isEmpty ? null : filterId)),
          ),
          IconButton(
            icon: Icon(Icons.search, color: AppThemeHelper.textPrimary(context)),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: AppThemeHelper.textPrimary(context)),
            onPressed: () {},
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
                onRetry: () => ref.refresh(productsStreamProvider(filterId)),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyState(category: selectedSubcategory?.name ?? selectedCategory?.name ?? 'all');
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(productsStreamProvider(filterId));
                  },
                  color: AppColors.primary,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) => _ProductCardWrapper(product: products[i]),
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
    return ProductCard(
      product: product,
      onFavorite: () async {
        final user = ref.read(authStateProvider).value;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to add favorites')),
          );
          return;
        }
        await ref.read(favoriteNotifierProvider.notifier).toggleFavorite(product.id);
        ref.invalidate(userFavoritesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(product.isFavorite ? 'Removed from favorites' : 'Added to favorites'),
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
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(selectedHomeCategoryProvider);
    
    debugPrint('[HomeScreen] Categories async state: ${categoriesAsync.whenOrNull}');
    debugPrint('[HomeScreen] Selected category: ${selectedCategory?.name}');

    return SizedBox(
      height: 40,
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (categories) {
          debugPrint('[HomeScreen] Loaded ${categories.length} categories');
          final items = [CategoryEntity(id: '', name: 'All'), ...categories];
          
          if (categories.isEmpty) {
            return GestureDetector(
              onTap: () {
                debugPrint('[HomeScreen] Retrying categories load');
                ref.invalidate(categoriesStreamProvider);
              },
              child: const Center(
                child: Text('No categories. Tap to retry', 
                  style: TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }
          
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = items[index];
              final isSelected = category.id == selectedCategory?.id || 
                  (selectedCategory == null && category.id == '');
              final label = category.name;
              final displayLabel = label.isEmpty ? 'All' : label;

              return GestureDetector(
                onTap: () {
                  ref.read(selectedHomeCategoryProvider.notifier).select(category);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    displayLabel,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textPrimary,
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

class _SubcategoryFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedHomeCategoryProvider);
    final selectedSubcategory = ref.watch(selectedHomeSubcategoryProvider);
    
    // Only show subcategories if a category is selected
    if (selectedCategory == null) {
      return const SizedBox.shrink();
    }
    
    final subcategoriesAsync = ref.watch(subcategoriesStreamProvider(selectedCategory.id));
    
    return SizedBox(
      height: 36,
      child: subcategoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => const SizedBox.shrink(),
        data: (subcategories) {
          if (subcategories.isEmpty) {
            return const SizedBox.shrink();
          }
          
          final items = [SubcategoryEntity(id: '', name: 'All', categoryId: ''), ...subcategories];
          
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
                  ref.read(selectedHomeSubcategoryProvider.notifier).select(sub);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          const Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            category == 'all' || category.isEmpty
                ? 'Be the first to list a product!'
                : 'No $category products yet',
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}