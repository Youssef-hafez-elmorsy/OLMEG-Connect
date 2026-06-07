import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/features/admin/data/admin_audit_service.dart';
import 'package:olmeg_connect/features/auth/domain/entities/user_entity.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class AdminProductModerationScreen extends ConsumerWidget {
  const AdminProductModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(authStateProvider).value;
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
            return const AppLoadingState(label: 'Loading product moderation');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Product moderation failed to load',
              message: '${snapshot.error}',
            );
          }

          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final status = doc.data()['moderationStatus'] as String?;
            return status == null || status == 'pending_admin';
          }).toList();
          if (docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.fact_check_outlined,
              title: 'No products waiting for review',
              message:
                  'Pending and AI-flagged product submissions will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _BulkModerationBar(submissions: docs, actor: actor);
              }
              return _ModerationCard(
                submission: docs[index - 1],
                actor: actor,
              );
            },
          );
        },
      ),
    );
  }
}

class _ModerationCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> submission;
  final UserEntity? actor;

  const _ModerationCard({required this.submission, required this.actor});

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
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _softDelete(context, data),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Soft delete'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _shadowBan(context, data),
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const Text('Shadow ban'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _escalate(context, data),
                  icon: const Icon(Icons.priority_high),
                  label: const Text('Escalate'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _addNote(context),
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Admin note'),
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
    await AdminAuditService.record(
      actor: actor,
      action: 'product_approved',
      targetType: 'product',
      targetId: submission.id,
    );
    await AdminAuditService.moderationHistory(
      actor: actor,
      targetType: 'product',
      targetId: submission.id,
      status: 'approved',
      note: 'Product approved and published.',
    );

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
    await AdminAuditService.record(
      actor: actor,
      action: 'product_rejected',
      targetType: 'product_submission',
      targetId: submission.id,
    );
    await AdminAuditService.moderationHistory(
      actor: actor,
      targetType: 'product_submission',
      targetId: submission.id,
      status: 'rejected',
      note: data['moderationReason'] as String?,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product rejected.')),
      );
    }
  }

  Future<void> _softDelete(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    await submission.reference.update({
      'moderationStatus': 'soft_deleted',
      'moderationDecision': 'admin_soft_delete',
      'adminReviewedAt': FieldValue.serverTimestamp(),
      'deletedAt': FieldValue.serverTimestamp(),
    });
    await AdminAuditService.moderationHistory(
      actor: actor,
      targetType: 'product_submission',
      targetId: submission.id,
      status: 'soft_deleted',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission soft deleted.')),
      );
    }
  }

  Future<void> _shadowBan(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    await submission.reference.update({
      'moderationStatus': 'shadow_banned',
      'moderationDecision': 'admin_shadow_ban',
      'visibleInDiscovery': false,
      'adminReviewedAt': FieldValue.serverTimestamp(),
    });
    await AdminAuditService.moderationHistory(
      actor: actor,
      targetType: 'product_submission',
      targetId: submission.id,
      status: 'shadow_banned',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission hidden from discovery.')),
      );
    }
  }

  Future<void> _escalate(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    await submission.reference.update({
      'moderationStatus': 'escalated',
      'moderationDecision': 'admin_escalated',
      'escalatedAt': FieldValue.serverTimestamp(),
      'escalationReason': data['moderationReason'] ?? 'Needs senior review',
    });

    await FirebaseFirestore.instance.collection('support_tickets').add({
      'title': 'Escalated product moderation',
      'category': 'moderation',
      'status': 'open',
      'priority': 'urgent',
      'userId': data['sellerId'] ?? '',
      'productSubmissionId': submission.id,
      'summary': data['moderationReason'] ?? 'Product requires senior review.',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await AdminAuditService.moderationHistory(
      actor: actor,
      targetType: 'product_submission',
      targetId: submission.id,
      status: 'escalated',
      note: data['moderationReason'] as String?,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission escalated to support.')),
      );
    }
  }

  Future<void> _addNote(BuildContext context) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Note'),
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
    if (note == null || note.isEmpty) return;
    await submission.reference.set({
      'adminNotes': FieldValue.arrayUnion([
        {
          'note': note,
          'actorId': actor?.id,
          'createdAt': Timestamp.now(),
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AdminAuditService.moderationHistory(
      actor: actor,
      targetType: 'product_submission',
      targetId: submission.id,
      status: 'note_added',
      note: note,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin note saved.')),
      );
    }
  }
}

class _BulkModerationBar extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> submissions;
  final UserEntity? actor;

  const _BulkModerationBar({required this.submissions, required this.actor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text('${submissions.length} pending submissions',
                style: Theme.of(context).textTheme.titleMedium),
            OutlinedButton.icon(
              onPressed: () => _bulkUpdate(context, 'rejected'),
              icon: const Icon(Icons.close),
              label: const Text('Reject all'),
            ),
            ElevatedButton.icon(
              onPressed: () => _bulkUpdate(context, 'approved'),
              icon: const Icon(Icons.check),
              label: const Text('Approve all'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkUpdate(BuildContext context, String status) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final submission in submissions) {
      batch.set(
        submission.reference,
        {
          'moderationStatus': status,
          'moderationDecision': 'admin_bulk_$status',
          'adminReviewedAt': FieldValue.serverTimestamp(),
          'adminNote': 'Bulk $status from admin moderation queue.',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    await AdminAuditService.record(
      actor: actor,
      action: 'bulk_product_moderation_$status',
      targetType: 'product_submission',
      targetId: 'bulk',
      metadata: {'count': submissions.length},
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${submissions.length} submissions updated.')),
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
