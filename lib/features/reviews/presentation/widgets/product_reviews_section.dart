import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/reports/domain/entities/report_entity.dart';
import 'package:olmeg_connect/features/reports/presentation/providers/report_provider.dart';
import 'package:olmeg_connect/features/reviews/presentation/providers/review_provider.dart';

class ProductReviewsSection extends ConsumerWidget {
  final ProductEntity product;

  const ProductReviewsSection({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(product.id));
    final user = ref.watch(authStateProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Product reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (user != null && user.id != product.sellerId)
              TextButton.icon(
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Review'),
                onPressed: () => _showReviewDialog(context, ref, user.id),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        reviewsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Could not load reviews'),
          data: (reviews) {
            if (reviews.isEmpty) {
              return const Text(
                'No product reviews yet',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            return Column(
              children: [
                for (final review in reviews.take(3))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.star, color: AppColors.primary),
                      title: Text(
                        '${review.rating}/5${review.isVerifiedPurchase ? ' • Verified purchase' : ''}',
                      ),
                      subtitle: Text(review.body),
                      trailing: user == null
                          ? null
                          : IconButton(
                              tooltip: 'Report review',
                              icon: const Icon(Icons.report_outlined),
                              onPressed: () => createReport(
                                reporterId: user.id,
                                targetType: ReportTargetType.review,
                                targetId: review.id,
                                reason: 'Review reported from product page',
                              ),
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showReviewDialog(
    BuildContext context,
    WidgetRef ref,
    String buyerId,
  ) {
    var rating = 5;
    final bodyController = TextEditingController();
    final orderAsync = ref.read(completedOrderForReviewProvider(
      (buyerId: buyerId, productId: product.id),
    ));
    final order = orderAsync.value;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Review product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: rating,
                decoration: const InputDecoration(labelText: 'Rating'),
                items: [5, 4, 3, 2, 1]
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value stars'),
                        ))
                    .toList(),
                onChanged: (value) => rating = value ?? 5,
              ),
              TextField(
                controller: bodyController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Review'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await createProductReview(
                  ref: ref,
                  productId: product.id,
                  sellerId: product.sellerId,
                  buyerId: buyerId,
                  rating: rating,
                  body: bodyController.text.trim(),
                  orderId: order?.id,
                  isVerifiedPurchase: order != null,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
