import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/ratings/presentation/providers/rating_provider.dart';

class RatingWidget extends ConsumerWidget {
  final String userId;
  final bool showReviews;

  const RatingWidget({
    super.key,
    required this.userId,
    this.showReviews = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final averageRatingAsync = ref.watch(averageRatingProvider(userId));
    final ratingsAsync = ref.watch(userRatingsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        averageRatingAsync.when(
          data: (rating) {
            return Row(
              children: [
                _buildStars(rating),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(strokeWidth: 2),
          error: (_, __) => const Text('Error loading rating'),
        ),
        if (showReviews) ...[
          const SizedBox(height: AppSpacing.md),
          ratingsAsync.when(
            data: (ratings) {
              if (ratings.isEmpty) {
                return const Text(
                  'No reviews yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ratings.take(3).map((rating) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStars(rating.rating.toDouble()),
                          if (rating.review != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              rating.review!,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(strokeWidth: 2),
            error: (_, __) => const Text('Error loading reviews'),
          ),
        ],
      ],
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
                  ? Icons.star_half
                  : Icons.star_outline,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }
}
