import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SellerCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double rating;
  final int productsCount;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onCall;

  const SellerCard({
    super.key,
    required this.name,
    this.avatarUrl,
    this.rating = 0,
    this.productsCount = 0,
    this.onTap,
    this.onMessage,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!) as ImageProvider
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            '$productsCount products',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            // Action Buttons
            if (onMessage != null || onCall != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (onMessage != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMessage,
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: const Text('Message'),
                      ),
                    ),
                  if (onMessage != null && onCall != null)
                    const SizedBox(width: AppSpacing.sm),
                  if (onCall != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onCall,
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}