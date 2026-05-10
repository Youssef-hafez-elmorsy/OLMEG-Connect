import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';

class AdminProductModerationScreen extends StatelessWidget {
  const AdminProductModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Moderation'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('product_submissions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final status = doc.data()['moderationStatus'] as String?;
            return status == null || status == 'pending_admin';
          }).toList();
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No products waiting for review',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return _ModerationCard(submission: docs[index]);
            },
          );
        },
      ),
    );
  }
}

class _ModerationCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> submission;

  const _ModerationCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    final data = submission.data();
    final title = data['title'] as String? ?? 'Untitled product';
    final description = data['description'] as String? ?? '';
    final reason = data['moderationReason'] as String? ?? 'No reason provided.';
    final status = data['moderationStatus'] as String? ?? 'pending_admin';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final price = (data['price'] as num?)?.toDouble() ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumb(imageUrl: imageUrl),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        CurrencyFormatter.egp(price),
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        status.replaceAll('_', ' '),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(description),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border:
                    Border.all(color: Colors.orange.withValues(alpha: 0.35)),
              ),
              child: Text(
                'AI review: $reason',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context, data),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(context, data),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final productRef =
        FirebaseFirestore.instance.collection('products').doc(submission.id);
    final submissionRef = submission.reference;
    final sellerId = data['sellerId'] as String? ?? '';
    final title = data['title'] as String? ?? 'Your product';

    final productData = Map<String, dynamic>.from(data)
      ..['moderationStatus'] = 'approved'
      ..['moderationDecision'] = 'admin_approved'
      ..['adminReviewedAt'] = FieldValue.serverTimestamp()
      ..['publishedAt'] = FieldValue.serverTimestamp();

    final batch = FirebaseFirestore.instance.batch();
    batch.set(productRef, productData);
    batch.update(submissionRef, {
      'moderationStatus': 'approved',
      'moderationDecision': 'admin_approved',
      'adminReviewedAt': FieldValue.serverTimestamp(),
    });
    if (sellerId.isNotEmpty) {
      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': sellerId,
        'title': 'Product approved',
        'message': '$title is now published.',
        'body': '$title is now published.',
        'type': 'product_moderation',
        'relatedId': submission.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product approved and published.')),
      );
    }
  }

  Future<void> _reject(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final sellerId = data['sellerId'] as String? ?? '';
    final title = data['title'] as String? ?? 'Your product';
    final batch = FirebaseFirestore.instance.batch();

    batch.update(submission.reference, {
      'moderationStatus': 'rejected',
      'moderationDecision': 'admin_rejected',
      'adminReviewedAt': FieldValue.serverTimestamp(),
    });
    if (sellerId.isNotEmpty) {
      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': sellerId,
        'title': 'Product rejected',
        'message': '$title was rejected after admin review.',
        'body': '$title was rejected after admin review.',
        'type': 'product_moderation',
        'relatedId': submission.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product rejected.')),
      );
    }
  }
}

class _ProductThumb extends StatelessWidget {
  final String imageUrl;

  const _ProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const SizedBox(
        width: 72,
        height: 72,
        child: Icon(Icons.image_not_supported),
      );
    }

    if (imageUrl.startsWith('data:image')) {
      final commaIndex = imageUrl.indexOf(',');
      if (commaIndex != -1) {
        final bytes = base64Decode(imageUrl.substring(commaIndex + 1));
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.memory(
            bytes,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.network(
        imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 72,
          height: 72,
          child: Icon(Icons.broken_image),
        ),
      ),
    );
  }
}
