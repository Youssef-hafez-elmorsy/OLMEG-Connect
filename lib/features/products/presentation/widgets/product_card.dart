import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/buyer_experience_widgets.dart';
import 'package:olmeg_connect/features/auth/domain/entities/merchant_verification_entity.dart';
import '../../domain/entities/product_entity.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final VoidCallback? onTap;
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    this.onDelete,
    this.onFavorite,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);
    final borderColor = AppColors.getDivider(isDark);
    final surfaceColor = AppColors.getSurface(isDark);
    final statusColor = product.inStock ? AppColors.success : AppColors.error;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final deliveryLabel = product.supportsDelivery
        ? l10n?.t('deliveryReady') ?? 'Delivery ready'
        : l10n?.t('contactSeller') ?? 'Contact seller';
    final categoryLabel = _categoryLabel(context, product);
    final sellerVerified = product.sellerMerchantVerificationStatus ==
        MerchantVerificationStatus.approved;

    return Semantics(
      button: true,
      label: product.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap ??
              () => context.push('/product/${product.id}', extra: product),
          child: Ink(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: borderColor.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: compact ? 8 : 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.xl),
                        ),
                        child: _buildImage(context, isDark),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 64,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(
                                    alpha: isDark ? 0.32 : 0.18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.sm,
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.hasDiscount)
                              _Pill(
                                label: '-${product.discountPercent}%',
                                color: AppColors.error,
                              ),
                            const Spacer(),
                            if (onFavorite != null)
                              _CircleAction(
                                icon: product.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: product.isFavorite
                                    ? AppColors.error
                                    : textColor,
                                onTap: onFavorite,
                              ),
                            if (onDelete != null) ...[
                              const SizedBox(width: 6),
                              _CircleAction(
                                icon: Icons.delete_outline,
                                color: textColor,
                                onTap: onDelete,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(compact ? 10 : AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: compact ? 13 : 14,
                          height: 1.18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              CurrencyFormatter.egp(product.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                CurrencyFormatter.egp(product.originalPrice!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: compact ? 6 : 8),
                      if (compact)
                        _CompactCue(
                          icon: product.supportsDelivery
                              ? Icons.local_shipping_outlined
                              : Icons.chat_bubble_outline,
                          label: deliveryLabel,
                          color: product.supportsDelivery
                              ? AppColors.success
                              : AppColors.warning,
                        )
                      else ...[
                        BuyerSignalStrip(
                          items: [
                            BuyerSignalItem(
                              icon: product.supportsDelivery
                                  ? Icons.local_shipping_outlined
                                  : Icons.chat_bubble_outline,
                              label: deliveryLabel,
                              color: product.supportsDelivery
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            BuyerSignalItem(
                              icon: product.ratingAverage > 0
                                  ? Icons.star
                                  : Icons.category_outlined,
                              label: product.ratingAverage > 0
                                  ? product.ratingAverage.toStringAsFixed(1)
                                  : categoryLabel,
                              color: AppColors.warning,
                            ),
                            BuyerSignalItem(
                              icon: sellerVerified
                                  ? Icons.verified_user_outlined
                                  : Icons.storefront_outlined,
                              label: sellerVerified
                                  ? (l10n?.t('verifiedSeller') ??
                                      'Verified seller')
                                  : (l10n?.t('sellerProfile') ??
                                      'Seller profile'),
                              color: sellerVerified
                                  ? AppColors.primary
                                  : secondaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.inStock
                                    ? '${product.stockQuantity} ${l10n?.t('inStock') ?? 'in stock'}'
                                    : l10n?.t('outOfStock') ?? 'Out of stock',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (product.viewCount > 0) ...[
                              Icon(Icons.visibility_outlined,
                                  size: 14, color: secondaryColor),
                              const SizedBox(width: 3),
                              Text(
                                '${product.viewCount}',
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.sellerName.isEmpty
                              ? l10n?.t('marketplaceSeller') ??
                                  'Marketplace seller'
                              : product.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: secondaryColor, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool isDark) {
    final placeholderColor =
        isDark ? AppColors.getCard(isDark) : const Color(0xFFE8EEF4);
    if (product.imageUrl.isEmpty) {
      return _ImageFallback(
        color: placeholderColor,
        label: Localizations.of<AppLocalizations>(
              context,
              AppLocalizations,
            )?.t('noImage') ??
            'No image',
      );
    }

    if (product.imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(product.imageUrl.split(',').last);
        return Image.memory(
          Uint8List.fromList(bytes),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _ImageFallback(color: placeholderColor),
        );
      } catch (_) {
        return _ImageFallback(color: placeholderColor);
      }
    }

    if (!product.imageUrl.startsWith('http')) {
      return _ImageFallback(color: placeholderColor);
    }

    return CachedNetworkImage(
      imageUrl: product.imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: placeholderColor,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => _ImageFallback(color: placeholderColor),
    );
  }
}

String _categoryLabel(BuildContext context, ProductEntity product) {
  final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
  final category = product.category.trim();
  if (category.isNotEmpty) return l10n?.categoryLabel(category) ?? category;
  return l10n?.t('uncategorized') ?? 'Uncategorized';
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactCue extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompactCue({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final Color color;
  final String label;

  const _ImageFallback({
    required this.color,
    this.label = 'Image unavailable',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 38, color: Colors.grey.shade500),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
