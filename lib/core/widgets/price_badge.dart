import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PriceBadge extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final String currency;
  final bool showDiscount;

  const PriceBadge({
    super.key,
    required this.price,
    this.originalPrice,
    this.currency = '\$',
    this.showDiscount = true,
  });

  bool get hasDiscount =>
      showDiscount && originalPrice != null && originalPrice! > price;

  int get discountPercent =>
      hasDiscount ? ((1 - price / originalPrice!) * 100).round() : 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$currency${price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$currency${originalPrice!.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '-$discountPercent%',
              style: const TextStyle(
                color: AppColors.background,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PriceTag extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final String currency;
  final bool large;

  const PriceTag({
    super.key,
    required this.price,
    this.originalPrice,
    this.currency = '\$',
    this.large = false,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  int get discountPercent =>
      hasDiscount ? ((1 - price / originalPrice!) * 100).round() : 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              price.toStringAsFixed(0),
              style: TextStyle(
                fontSize: large ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              currency,
              style: TextStyle(
                fontSize: large ? 16 : 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (hasDiscount) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                originalPrice!.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$discountPercent% OFF',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.background,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}