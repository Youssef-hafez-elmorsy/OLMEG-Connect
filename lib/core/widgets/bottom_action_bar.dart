import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final String? cartLabel;
  final String? buyLabel;
  final bool isLoading;
  final bool showDivider;

  const BottomActionBar({
    super.key,
    this.onAddToCart,
    this.onBuyNow,
    this.cartLabel,
    this.buyLabel,
    this.isLoading = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.surfaceLight,
        border: showDivider
            ? Border(
                top: BorderSide(
                  color: isDark ? AppColors.divider : AppColors.dividerLight,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: cartLabel ?? 'Add to Cart',
                icon: Icons.shopping_cart_outlined,
                isPrimary: false,
                isLoading: isLoading,
                onTap: onAddToCart,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: _ActionButton(
                label: buyLabel ?? 'Buy Now',
                icon: Icons.bolt,
                isPrimary: true,
                isLoading: isLoading,
                onTap: onBuyNow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor =
        isDisabled ? AppColors.textSecondary : AppColors.primary;
    final textColor = isPrimary
        ? AppColors.background
        : isDark
            ? AppColors.textPrimary
            : AppColors.textPrimaryLight;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.textSecondary.withValues(alpha: 0.18)
              : isPrimary
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: outlineColor.withValues(alpha: isDisabled ? 0.40 : 1),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? AppColors.background : outlineColor,
                ),
              )
            else
              Icon(
                icon,
                size: 20,
                color: isDisabled ? AppColors.textSecondary : textColor,
              ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? AppColors.textSecondary : textColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppFloatingActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String? label;
  final bool isLoading;

  const AppFloatingActionButton({
    super.key,
    this.onTap,
    this.icon = Icons.add,
    this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.background,
                  ),
                ),
              )
            : Icon(
                icon,
                color: AppColors.background,
                size: 28,
              ),
      ),
    );
  }
}
