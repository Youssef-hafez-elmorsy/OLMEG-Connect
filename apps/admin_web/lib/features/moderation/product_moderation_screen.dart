import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/actions/admin_action_service.dart';
import '../shared/admin_action_dialogs.dart';
import '../shared/admin_collection_table_page.dart';

class ProductModerationScreen extends StatelessWidget {
  const ProductModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Product Moderation',
      description:
          'Review pending, reported, rejected, and escalated listings.',
      icon: Icons.verified_user_outlined,
      collectionName: 'product_submissions',
      serverFilterOptions: const [
        AdminServerFilterOption(
          label: 'Needs review',
          icon: Icons.pending_actions_outlined,
          filters: [
            AdminServerFilter.equals('moderationStatus', 'pending'),
          ],
        ),
        AdminServerFilterOption(
          label: 'Escalated',
          icon: Icons.priority_high,
          filters: [
            AdminServerFilter.equals('moderationStatus', 'escalated'),
          ],
        ),
        AdminServerFilterOption(
          label: 'Approved',
          icon: Icons.check_circle_outline,
          filters: [
            AdminServerFilter.equals('moderationStatus', 'approved'),
          ],
        ),
        AdminServerFilterOption(
          label: 'Rejected',
          icon: Icons.block_outlined,
          filters: [
            AdminServerFilter.equals('moderationStatus', 'rejected'),
          ],
        ),
      ],
      columns: [
        AdminTableColumn.image(
          'Photo',
          fields: [
            'imageUrl',
            'thumbnailUrl',
            'images',
            'imageUrls',
            'productImageUrl',
          ],
        ),
        AdminTableColumn.field('Status', 'moderationStatus', status: true),
        AdminTableColumn.field('AI Risk', 'aiRiskLevel', status: true),
        AdminTableColumn.field('AI Action', 'aiSuggestedAction'),
        AdminTableColumn.field('Product', 'productId'),
        AdminTableColumn.field('Title', 'title'),
        AdminTableColumn.field('Seller', 'sellerId'),
        AdminTableColumn.field('AI Reasons', 'aiReasons'),
        AdminTableColumn.field('AI Signals', 'aiSignals'),
        AdminTableColumn.field('Reason', 'reason'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: _moderationActions,
    );
  }
}

List<Widget> _moderationActions(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final service = AdminActionService();

  Future<void> moderate(String status, String label) async {
    final reason = await askAdminReason(
      context,
      title: label,
      actionLabel: label,
      message: 'This updates product moderation and writes an audit log.',
    );
    if (reason == null) return;
    try {
      await service.updateWithAudit(
        targetRef: doc.reference,
        data: {
          'moderationStatus': status,
          'moderationDecision': 'admin_$status',
        },
        action: 'product_moderation_$status',
        targetType: 'product_submissions',
        reason: reason,
        metadata: {'submissionId': doc.id},
      );
      if (!context.mounted) return;
      showAdminSnack(context, 'Product marked $status.');
    } catch (error) {
      if (!context.mounted) return;
      showAdminSnack(context, 'Action failed: $error', isError: true);
    }
  }

  return [
    FilledButton.tonalIcon(
      onPressed: () => moderate('approved', 'Approve product'),
      icon: const Icon(Icons.check),
      label: const Text('Approve'),
    ),
    OutlinedButton.icon(
      onPressed: () => moderate('rejected', 'Reject product'),
      icon: const Icon(Icons.close),
      label: const Text('Reject'),
    ),
    OutlinedButton.icon(
      onPressed: () => moderate('hidden', 'Hide product'),
      icon: const Icon(Icons.visibility_off_outlined),
      label: const Text('Hide'),
    ),
    OutlinedButton.icon(
      onPressed: () => moderate('escalated', 'Escalate product'),
      icon: const Icon(Icons.priority_high),
      label: const Text('Escalate'),
    ),
  ];
}
