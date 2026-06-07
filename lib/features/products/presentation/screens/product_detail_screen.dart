import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/constants/app_constants.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/buyer_experience_widgets.dart';
import 'package:olmeg_connect/core/widgets/common_widgets.dart';
import 'package:olmeg_connect/core/widgets/product_color_swatch.dart' as swatch;
import 'package:olmeg_connect/core/widgets/screen_performance_probe.dart';
import 'package:olmeg_connect/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:olmeg_connect/features/cart/domain/entities/cart_item.dart';
import 'package:olmeg_connect/features/cart/presentation/providers/local_cart_provider.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/products/presentation/providers/product_discovery_provider.dart';
import 'package:olmeg_connect/features/products/presentation/providers/product_provider.dart';
import 'package:olmeg_connect/features/reports/domain/entities/report_entity.dart';
import 'package:olmeg_connect/features/reports/presentation/providers/report_provider.dart';
import 'package:olmeg_connect/features/reviews/presentation/widgets/product_reviews_section.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/chat/presentation/providers/chat_provider.dart';
import 'package:olmeg_connect/features/ratings/presentation/widgets/rating_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductEntity product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  String? _selectedColor;
  ProductVariant? _selectedVariant;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
    Future.microtask(() async {
      await saveRecentlyViewedProduct(widget.product.id);
      ref.invalidate(recentlyViewedIdsProvider);
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        // Product views are written as scattered analytics events instead of
        // incrementing the same product document for every popular-product open.
        await ref
            .read(analyticsServiceProvider)
            .trackProductViewed(user.id, widget.product.id)
            .catchError((_) {});
      }
    });
  }

  void _toggleFavorite() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add favorites')),
      );
      return;
    }

    setState(() => _isFavorite = !_isFavorite);

    await ref
        .read(favoriteNotifierProvider.notifier)
        .toggleFavorite(widget.product.id);
    await ref
        .read(analyticsServiceProvider)
        .trackFavorite(user.id, widget.product.id)
        .catchError((_) {});
    await FirebaseFirestore.instance
        .collection('product_alerts')
        .doc('${user.id}_${widget.product.id}')
        .set({
      'userId': user.id,
      'productId': widget.product.id,
      'sellerId': widget.product.sellerId,
      'priceAtSave': widget.product.price,
      'alertTypes': ['price_drop', 'back_in_stock'],
      'enabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _startChat(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to chat')),
      );
      return;
    }

    // Check if user is the seller
    if (user.id == widget.product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself')),
      );
      return;
    }

    try {
      final chatId = await ref.read(chatNotifierProvider.notifier).createChat(
            productId: widget.product.id,
            productTitle: widget.product.title,
            buyerId: user.id,
            buyerName: user.name,
            sellerId: widget.product.sellerId,
            sellerName: widget.product.sellerName,
          );

      if (chatId != null && context.mounted) {
        final chat =
            await ref.read(chatRemoteDataSourceProvider).getChatById(chatId);
        if (chat != null && context.mounted) {
          context.push('/chat/$chatId', extra: chat);
        }
      } else if (chatId == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create chat. Try again.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _buyNow(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to purchase')),
      );
      return;
    }

    if (!widget.product.inStock || _quantity > widget.product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected quantity is not available')),
      );
      return;
    }

    final added = _addCurrentProductToCart(showSnackBar: false);
    if (added && context.mounted) {
      context.push('/checkout');
    }
  }

  void _addToCart() {
    _addCurrentProductToCart(showSnackBar: true);
  }

  bool _addCurrentProductToCart({required bool showSnackBar}) {
    final product = widget.product;
    if (!product.inStock || _quantity > product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected quantity is not available')),
      );
      return false;
    }

    ref.read(cartProvider.notifier).addItem(
          CartItem(
            id: product.id,
            title: product.title,
            price: product.price + (_selectedVariant?.priceDelta ?? 0),
            imageUrl: product.imageUrl,
            sellerId: product.sellerId,
            sellerName: product.sellerName,
            selectedVariant: _selectedVariant?.label ?? _selectedColor,
            stockQuantity: _selectedVariant?.stockQuantity ?? product.stock,
            quantity: _quantity,
          ),
        );
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref
          .read(analyticsServiceProvider)
          .trackAddToCart(user.id, product.id, _quantity)
          .catchError((_) {});
    }
    if (showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.title} added to cart'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => context.push('/cart'),
          ),
        ),
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final user = ref.watch(authStateProvider).value;
    final isOwner = user?.id == product.sellerId;
    final images = product.allImages;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenPerformanceProbe(
        screenName: 'product_detail',
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary),
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color:
                          _isFavorite ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.report_outlined),
                            title: const Text('Report product'),
                            onTap: () async {
                              Navigator.pop(context);
                              final user = ref.read(authStateProvider).value;
                              if (user == null) return;
                              await createReport(
                                reporterId: user.id,
                                targetType: ReportTargetType.product,
                                targetId: product.id,
                                reason: 'Product reported from detail page',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Report submitted')),
                                );
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.storefront_outlined),
                            title: const Text('Report seller'),
                            onTap: () async {
                              Navigator.pop(context);
                              final user = ref.read(authStateProvider).value;
                              if (user == null) return;
                              await createReport(
                                reporterId: user.id,
                                targetType: ReportTargetType.seller,
                                targetId: product.sellerId,
                                reason: 'Seller reported from product page',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Report submitted')),
                                );
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.share),
                            title: const Text('Share Product'),
                            onTap: () {
                              final link =
                                  AppConstants.productShareUrl(product.id);
                              Clipboard.setData(ClipboardData(text: link));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Product link copied!'),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.link),
                            title: const Text('Copy Link'),
                            onTap: () {
                              final link =
                                  AppConstants.productShareUrl(product.id);
                              Clipboard.setData(ClipboardData(text: link));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Link copied!')),
                              );
                            },
                          ),
                          if (product.city.trim().isNotEmpty)
                            ListTile(
                              leading: const Icon(Icons.map_outlined),
                              title: const Text('Copy Google Maps location'),
                              onTap: () {
                                final link = Uri.https(
                                  'www.google.com',
                                  '/maps/search/',
                                  {'api': '1', 'query': product.city},
                                ).toString();
                                Clipboard.setData(ClipboardData(text: link));
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Map location copied!'),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.share, color: AppColors.textPrimary),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: images.isNotEmpty
                    ? ImageGallery(images: images, height: 300)
                    : Container(
                        color: AppColors.card,
                        child: const Icon(Icons.image_outlined,
                            size: 64, color: AppColors.textSecondary),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            product.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (product.rating > 0)
                      Row(
                        children: [
                          ...List.generate(
                              5,
                              (i) => Icon(
                                    i < product.rating.floor()
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 18,
                                    color: AppColors.primary,
                                  )),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${product.rating.toStringAsFixed(1)} (${product.reviewsCount} reviews)',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),
                    RatingWidget(userId: product.sellerId, showReviews: true),
                    const SizedBox(height: AppSpacing.lg),
                    ProductReviewsSection(product: product),
                    const SizedBox(height: AppSpacing.lg),
                    PriceBadge(
                        price: product.price,
                        originalPrice: product.originalPrice),
                    const SizedBox(height: AppSpacing.lg),
                    _ProductHighlightsSection(product: product),
                    const SizedBox(height: AppSpacing.lg),
                    _SpecificationTable(product: product),
                    const SizedBox(height: AppSpacing.lg),
                    _TrustPanel(product: product),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(product.city,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        if (product.city.trim().isNotEmpty)
                          IconButton(
                            tooltip: 'Open in Google Maps',
                            onPressed: () => _openMap(product.city),
                            icon: const Icon(Icons.map_outlined),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.inStock
                                ? AppColors.success.withValues(alpha: 0.2)
                                : AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            product.inStock ? 'In Stock' : 'Out of Stock',
                            style: TextStyle(
                              color: product.inStock
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CommerceInfoTile(
                      icon: Icons.visibility_outlined,
                      title: 'Visitors',
                      value: '${product.viewCount + 1} product views',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CommerceInfoTile(
                      icon: product.supportsDelivery
                          ? Icons.local_shipping_outlined
                          : Icons.chat_bubble_outline,
                      title: product.supportsDelivery
                          ? 'Delivery'
                          : 'Contact seller',
                      value: product.deliveryDisplayText,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CommerceInfoTile(
                      icon: Icons.assignment_return_outlined,
                      title: 'Returns',
                      value: product.returnPolicy ??
                          'Contact seller for return details',
                    ),
                    const Divider(height: AppSpacing.xl),
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(product.description,
                        style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: AppColors.textSecondary)),
                    if (product.features.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const Text('Features',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: product.features
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.xl),
                                    border:
                                        Border.all(color: AppColors.divider),
                                  ),
                                  child: Text(f,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary)),
                                ))
                            .toList(),
                      ),
                    ],
                    if (product.colors.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const Text('Colors',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.sm),
                      swatch.ColorSwatch(
                        colors: product.colors,
                        selectedColor: _selectedColor,
                        onColorSelected: (c) =>
                            setState(() => _selectedColor = c),
                      ),
                    ],
                    if (product.variants.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const Text('Options',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: product.variants.map((variant) {
                          final selected = _selectedVariant?.id == variant.id;
                          return ChoiceChip(
                            label: Text(
                              variant.priceDelta == null ||
                                      variant.priceDelta == 0
                                  ? variant.label
                                  : '${variant.label} +${CurrencyFormatter.egp(variant.priceDelta!)}',
                            ),
                            selected: selected,
                            onSelected: variant.stockQuantity <= 0
                                ? null
                                : (_) => setState(() {
                                      _selectedVariant = variant;
                                      _quantity = 1;
                                    }),
                          );
                        }).toList(),
                      ),
                    ],
                    if (product.supportsDelivery) ...[
                      const SizedBox(height: AppSpacing.xl),
                      QuantitySelector(
                        label: 'Quantity',
                        quantity: _quantity,
                        maxQuantity: product.stock,
                        onChanged: (q) => setState(() => _quantity = q),
                      ),
                    ] else ...[
                      const SizedBox(height: AppSpacing.xl),
                      const _CommerceInfoTile(
                        icon: Icons.chat_bubble_outline,
                        title: 'Order by contact',
                        value:
                            'This product is handled directly with the seller. Message them to agree on pickup, delivery, and payment.',
                      ),
                    ],
                    const Divider(height: AppSpacing.xl),
                    _ProductQuestionSection(product: product),
                    const Divider(height: AppSpacing.xl),
                    _ComparisonBlock(product: product),
                    const SizedBox(height: AppSpacing.lg),
                    _BundleSuggestion(product: product),
                    const Divider(height: AppSpacing.xl),
                    if (!isOwner)
                      SellerCard(
                        name: product.sellerName,
                        avatarUrl: product.sellerAvatar,
                        rating: product.sellerRating,
                        productsCount: product.sellerProducts,
                        onMessage: () => _startChat(context, ref),
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                    const Text('Related products',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.sm),
                    _RelatedProducts(product: product),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: product.supportsDelivery
          ? BottomActionBar(
              cartLabel: 'Add to cart',
              buyLabel: 'Start order',
              onAddToCart: product.inStock ? _addToCart : null,
              onBuyNow: product.inStock ? () => _buyNow(context, ref) : null,
            )
          : !isOwner
              ? BottomActionBar(
                  cartLabel: 'Contact Seller',
                  buyLabel: 'Message Seller',
                  onAddToCart: () => _startChat(context, ref),
                  onBuyNow: () => _startChat(context, ref),
                )
              : null,
    );
  }

  Future<void> _openMap(String city) async {
    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': city},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Map link copied.')),
        );
      }
    }
  }
}

class _RelatedProducts extends ConsumerWidget {
  final ProductEntity product;

  const _RelatedProducts({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(relatedProductsProvider(product));
    return relatedAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) {
          return const Text(
            'No related products yet',
            style: TextStyle(color: AppColors.textSecondary),
          );
        }
        return SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final related = products[index];
              return InkWell(
                onTap: () =>
                    context.push('/product/${related.id}', extra: related),
                child: SizedBox(
                  width: 160,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            related.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.egp(related.price),
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductHighlightsSection extends StatelessWidget {
  final ProductEntity product;

  const _ProductHighlightsSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final highlights = [
      if (product.brand != null) 'Brand: ${product.brand}',
      if (product.condition != null) 'Condition: ${product.condition}',
      if (product.inStock) '${product.stockQuantity} available',
      if (product.hasDiscount) '${product.discountPercent}% off',
      if (product.supportsDelivery) 'Approved merchant delivery',
      ...product.features.take(3),
    ];
    if (highlights.isEmpty) return const SizedBox.shrink();
    return _DetailBlock(
      title: 'Highlights',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final highlight in highlights)
            Chip(
              avatar: const Icon(Icons.check_circle_outline, size: 16),
              label: Text(highlight),
            ),
        ],
      ),
    );
  }
}

class _SpecificationTable extends StatelessWidget {
  final ProductEntity product;

  const _SpecificationTable({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <String, String>{
      'Category': product.category,
      if (product.subCategoryName != null)
        'Subcategory': product.subCategoryName!,
      if (product.brand != null) 'Brand': product.brand!,
      if (product.condition != null) 'Condition': product.condition!,
      'Seller': product.sellerName,
      'Location': product.city.isEmpty ? 'Not specified' : product.city,
      'Stock': product.inStock ? '${product.stockQuantity}' : 'Out of stock',
    };
    return _DetailBlock(
      title: 'Specifications',
      child: Table(
        columnWidths: const {0: FlexColumnWidth(0.8), 1: FlexColumnWidth(1.2)},
        border: TableBorder.all(color: AppColors.divider),
        children: [
          for (final entry in rows.entries)
            TableRow(
              children: [
                _SpecCell(entry.key, isHeader: true),
                _SpecCell(entry.value),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProductQuestionSection extends ConsumerWidget {
  final ProductEntity product;

  const _ProductQuestionSection({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final canAnswer = user?.id == product.sellerId || user?.isAdmin == true;
    return _DetailBlock(
      title: 'Questions & answers',
      trailing: TextButton.icon(
        onPressed: () => _askQuestion(context, ref),
        icon: const Icon(Icons.help_outline),
        label: const Text('Ask'),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('product_questions')
            .where('productId', isEqualTo: product.id)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Text(
              'No questions yet. Ask the seller for details before buying.',
              style: TextStyle(color: AppColors.textSecondary),
            );
          }
          return Column(
            children: [
              for (final doc in docs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.question_answer_outlined),
                  title: Text(doc.data()['question'] as String? ?? ''),
                  subtitle: Text(
                    doc.data()['answer'] as String? ?? 'Waiting for answer',
                  ),
                  trailing: canAnswer
                      ? TextButton(
                          onPressed: () => _answerQuestion(context, doc),
                          child: const Text('Answer'),
                        )
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _answerQuestion(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final controller = TextEditingController();
    final answer = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Answer question'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Answer'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (answer == null || answer.isEmpty) return;
    await doc.reference.set({
      'answer': answer,
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer saved.')),
      );
    }
  }

  Future<void> _askQuestion(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to ask a question.')),
      );
      return;
    }
    final controller = TextEditingController();
    final question = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ask seller'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Question'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (question == null || question.isEmpty) return;
    await FirebaseFirestore.instance.collection('product_questions').add({
      'productId': product.id,
      'sellerId': product.sellerId,
      'buyerId': user.id,
      'question': question,
      'answer': null,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question sent.')),
      );
    }
  }
}

class _ComparisonBlock extends StatelessWidget {
  final ProductEntity product;

  const _ComparisonBlock({required this.product});

  @override
  Widget build(BuildContext context) {
    return _DetailBlock(
      title: 'Compare at a glance',
      child: Row(
        children: [
          Expanded(
              child: _CompareMetric(
                  'Price', CurrencyFormatter.egp(product.price))),
          Expanded(
              child: _CompareMetric(
                  'Rating',
                  product.ratingAverage > 0
                      ? product.ratingAverage.toStringAsFixed(1)
                      : 'New')),
          Expanded(
              child: _CompareMetric(
                  'Delivery', product.supportsDelivery ? 'Yes' : 'Contact')),
        ],
      ),
    );
  }
}

class _BundleSuggestion extends StatelessWidget {
  final ProductEntity product;

  const _BundleSuggestion({required this.product});

  @override
  Widget build(BuildContext context) {
    return _DetailBlock(
      title: 'Frequently bought together',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.add_shopping_cart_outlined),
        title: Text(product.hasDiscount
            ? 'Bundle with related deals'
            : 'Bundle with related products'),
        subtitle: Text(
          product.supportsDelivery
              ? 'Add compatible items from the same merchant to save delivery time.'
              : 'Message the seller to agree on bundle pickup or delivery.',
        ),
      ),
    );
  }
}

class _TrustPanel extends StatelessWidget {
  final ProductEntity product;

  const _TrustPanel({required this.product});

  @override
  Widget build(BuildContext context) {
    return _DetailBlock(
      title: 'Trust & safety',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              BuyerTrustChip(
                icon: product.supportsDelivery
                    ? Icons.local_shipping_outlined
                    : Icons.chat_bubble_outline,
                label: product.supportsDelivery
                    ? 'Delivery ready'
                    : 'Contact seller',
                color: product.supportsDelivery
                    ? AppColors.success
                    : AppColors.warning,
              ),
              BuyerTrustChip(
                icon: Icons.visibility_outlined,
                label: '${product.viewCount + 1} views',
              ),
              BuyerTrustChip(
                icon: product.inStock
                    ? Icons.inventory_2_outlined
                    : Icons.remove_shopping_cart_outlined,
                label: product.inStock ? 'In stock' : 'Out of stock',
                color: product.inStock ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _CommerceInfoTile(
            icon: Icons.verified_user_outlined,
            title: 'Seller verification',
            value: product.supportsDelivery
                ? 'Approved merchant for delivery'
                : 'Delivery is not enabled for this seller/product',
          ),
          const SizedBox(height: AppSpacing.sm),
          _CommerceInfoTile(
            icon: Icons.assignment_return_outlined,
            title: 'Return window',
            value: product.returnPolicy ?? 'Contact seller for return details',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _CommerceInfoTile(
            icon: Icons.flag_outlined,
            title: 'Report action',
            value: 'Use the share menu to report the product or seller.',
          ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _DetailBlock({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _SpecCell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _SpecCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Text(
        text,
        style: TextStyle(
          color: isHeader ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _CompareMetric extends StatelessWidget {
  final String label;
  final String value;

  const _CompareMetric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _CommerceInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _CommerceInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
