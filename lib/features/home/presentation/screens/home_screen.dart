import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/theme/app_theme_helper.dart';
import 'package:olmeg_connect/core/widgets/app_brand.dart';
import 'package:olmeg_connect/core/widgets/buyer_experience_widgets.dart';
import 'package:olmeg_connect/core/widgets/loading_widget.dart';
import 'package:olmeg_connect/core/widgets/screen_performance_probe.dart';
import 'package:olmeg_connect/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:olmeg_connect/features/products/domain/entities/category_entity.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/products/presentation/providers/product_discovery_provider.dart';
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

  static const double _maxContentWidth = 1180;

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
        toolbarHeight: 72,
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBrandLockup(
              logoSize: 38,
              titleSize: 16,
              taglineSize: 10,
              titleColor: AppThemeHelper.textPrimary(context),
              taglineColor: AppThemeHelper.textSecondary(context),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.hello(user?.name.split(' ').first ?? l10n.there),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: AppThemeHelper.textSecondary(context),
                fontWeight: FontWeight.normal,
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
      body: ScreenPerformanceProbe(
        screenName: 'home',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeSearchBand(
              onSearch: () => context.push('/advanced-search'),
              onCart: () => context.push('/cart'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _CategoryFilter(),
            const SizedBox(height: AppSpacing.sm),
            _SubcategoryFilter(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: productsAsync.when(
                loading: () => const ShimmerGrid(),
                error: (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry: () async => await ref
                      .refresh(productsStreamProvider(filterId).future),
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
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _ConstrainedHomeSection(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                                AppSpacing.sm,
                              ),
                              child: _MarketplaceHero(
                                userName:
                                    user?.name.split(' ').first ?? l10n.there,
                                onSearch: () =>
                                    context.push('/advanced-search'),
                                onCart: () => context.push('/cart'),
                              ),
                            ),
                          ),
                        ),
                        if (filterId.isEmpty) ...[
                          SliverToBoxAdapter(
                            child: _DiscoverySection(
                              titleKey: 'aiPicks',
                              subtitleKey: 'aiPicksSubtitle',
                              products: ref.watch(aiRecommendationsProvider),
                              analyticsSource: 'ai_recommendations',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _DiscoverySection(
                              titleKey: 'sponsored',
                              subtitleKey: 'sponsoredSubtitle',
                              products: ref.watch(sponsoredProductsProvider),
                              analyticsSource: 'sponsored',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _DiscoverySection(
                              titleKey: 'deals',
                              subtitleKey: 'dealsSubtitle',
                              products: ref.watch(dealProductsProvider),
                              analyticsSource: 'deals',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _DiscoverySection(
                              titleKey: 'topRated',
                              subtitleKey: 'topRatedSubtitle',
                              products: ref.watch(topRatedProductsProvider),
                              analyticsSource: 'top_rated',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _DiscoverySection(
                              titleKey: 'recommendedForYou',
                              subtitleKey: 'recommendedSubtitle',
                              products: ref
                                  .watch(personalizedRecommendationsProvider),
                              analyticsSource: 'personalized_recommendations',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _DiscoverySection(
                              titleKey: 'recentlyViewed',
                              subtitleKey: 'recentlyViewedSubtitle',
                              products:
                                  ref.watch(recentlyViewedProductsProvider),
                              analyticsSource: 'recently_viewed',
                            ),
                          ),
                        ],
                        _ResponsiveProductGrid(
                          products: products,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstrainedHomeSection extends StatelessWidget {
  final Widget child;

  const _ConstrainedHomeSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: HomeScreen._maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}

class _HomeSearchBand extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onCart;

  const _HomeSearchBand({
    required this.onSearch,
    required this.onCart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = AppThemeHelper.divider(context);
    final textColor = AppThemeHelper.textPrimary(context);
    final secondaryColor = AppThemeHelper.textSecondary(context);

    return _ConstrainedHomeSection(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.full),
                onTap: onSearch,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeHelper.surface(context),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.05,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: secondaryColor, size: 21),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.t('searchProducts'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.tune,
                        color: textColor,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              tooltip: l10n.t('openCart'),
              onPressed: onCart,
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceHero extends StatelessWidget {
  final String userName;
  final VoidCallback onSearch;
  final VoidCallback onCart;

  const _MarketplaceHero({
    required this.userName,
    required this.onSearch,
    required this.onCart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BuyerHeroPanel(
      eyebrow: l10n.t('marketplacePicks'),
      title: '${l10n.t('findRightDeal')}, $userName',
      message: l10n.t('homeHeroMessage'),
      icon: Icons.auto_awesome,
      stats: [
        BuyerTrustChip(
          icon: Icons.verified_user_outlined,
          label: l10n.t('trustedSellers'),
        ),
        BuyerTrustChip(
          icon: Icons.local_shipping_outlined,
          label: l10n.t('deliveryReadyItems'),
          color: AppColors.success,
        ),
        BuyerTrustChip(
          icon: Icons.chat_bubble_outline,
          label: l10n.t('chatBeforeBuying'),
          color: AppColors.warning,
        ),
      ],
      action: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
              label: Text(l10n.t('searchForProducts')),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filledTonal(
            tooltip: l10n.t('openCart'),
            onPressed: onCart,
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
    );
  }
}

class _DiscoverySection extends StatelessWidget {
  final String titleKey;
  final String subtitleKey;
  final AsyncValue<List<ProductEntity>> products;
  final String analyticsSource;

  const _DiscoverySection({
    required this.titleKey,
    required this.subtitleKey,
    required this.products,
    required this.analyticsSource,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return products.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return _ConstrainedHomeSection(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: BuyerSectionHeader(
                    title: l10n.t(titleKey),
                    subtitle: l10n.t(subtitleKey),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth =
                        constraints.maxWidth < 520 ? 184.0 : 204.0;
                    return SizedBox(
                      height: cardWidth * 1.36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: cardWidth,
                            child: _ProductCardWrapper(
                              product: items[index],
                              recommendationSource: analyticsSource,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResponsiveProductGrid extends StatelessWidget {
  final List<ProductEntity> products;

  const _ResponsiveProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final contentWidth = width > HomeScreen._maxContentWidth
            ? HomeScreen._maxContentWidth
            : width;
        final horizontalPadding =
            ((width - contentWidth) / 2).clamp(0.0, double.infinity) +
                AppSpacing.md;
        final maxCardWidth = width < 520 ? 210.0 : 236.0;

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.sm,
            horizontalPadding,
            AppSpacing.lg,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxCardWidth,
              childAspectRatio: 0.62,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ProductCardWrapper(product: products[i]),
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }
}

class _ProductCardWrapper extends ConsumerWidget {
  final ProductEntity product;
  final String? recommendationSource;

  const _ProductCardWrapper({
    required this.product,
    this.recommendationSource,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).value;
    final isOwner = user?.id == product.sellerId;

    return ProductCard(
      product: product,
      compact: true,
      onTap: () {
        final source = recommendationSource;
        if (user != null && source != null) {
          ref
              .read(analyticsServiceProvider)
              .trackRecommendationClick(
                user.id,
                productId: product.id,
                source: source,
              )
              .catchError((_) {});
        }
        context.push('/product/${product.id}', extra: product);
      },
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
        if (!context.mounted) return;
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

    return _ConstrainedHomeSection(
      child: SizedBox(
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
                color: AppThemeHelper.surface(context),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppThemeHelper.divider(context)),
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
                final displayLabel = category.name.isEmpty
                    ? l10n.all
                    : l10n.categoryLabel(category.name);

                return GestureDetector(
                  onTap: () {
                    ref
                        .read(selectedHomeCategoryProvider.notifier)
                        .select(category.id.isEmpty ? null : category);
                    ref
                        .read(selectedHomeSubcategoryProvider.notifier)
                        .select(null);
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
                          : AppThemeHelper.surface(context),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppThemeHelper.divider(context),
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
                            : AppThemeHelper.textPrimary(context),
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

    return _ConstrainedHomeSection(
      child: SizedBox(
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
                final label = sub.name.isEmpty
                    ? l10n.all
                    : l10n.subcategoryLabel(sub.name);

                return GestureDetector(
                  onTap: () {
                    ref
                        .read(selectedHomeSubcategoryProvider.notifier)
                        .select(sub.id.isEmpty ? null : sub);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppThemeHelper.surface(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppThemeHelper.divider(context),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.background
                            : AppThemeHelper.textPrimary(context),
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
    final textColor = AppThemeHelper.textPrimary(context);
    final secondaryColor = AppThemeHelper.textSecondary(context);
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            category == 'all' || category == l10n.all || category.isEmpty
                ? l10n.firstProductPrompt
                : l10n.noCategoryProducts(_localizedFilterName(l10n, category)),
            style: TextStyle(
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedFilterName(AppLocalizations l10n, String category) {
  final subcategory = l10n.subcategoryLabel(category);
  if (subcategory != category) return subcategory;
  return l10n.categoryLabel(category);
}
