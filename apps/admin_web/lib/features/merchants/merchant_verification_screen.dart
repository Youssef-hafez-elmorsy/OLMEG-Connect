import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/actions/admin_action_service.dart';
import '../shared/admin_action_dialogs.dart';
import '../shared/admin_collection_table_page.dart';

class MerchantVerificationScreen extends StatelessWidget {
  const MerchantVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Merchant Verification',
      description: 'Review merchant onboarding and delivery eligibility.',
      icon: Icons.storefront_outlined,
      collectionName: 'merchant_verifications',
      serverFilterOptions: const [
        AdminServerFilterOption(
          label: 'Submitted',
          icon: Icons.pending_actions_outlined,
          filters: [
            AdminServerFilter.equals('status', 'submitted'),
          ],
        ),
        AdminServerFilterOption(
          label: 'Approved',
          icon: Icons.verified_outlined,
          filters: [
            AdminServerFilter.equals('status', 'approved'),
          ],
        ),
        AdminServerFilterOption(
          label: 'Rejected',
          icon: Icons.block_outlined,
          filters: [
            AdminServerFilter.equals('status', 'rejected'),
          ],
        ),
        AdminServerFilterOption(
          label: 'Suspended',
          icon: Icons.pause_circle_outline,
          filters: [
            AdminServerFilter.equals('status', 'suspended'),
          ],
        ),
      ],
      columns: [
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Business', 'legalBusinessName'),
        AdminTableColumn.field('Contact', 'contactEmail'),
        AdminTableColumn.field('Country', 'country'),
        AdminTableColumn.field('Submitted', 'submittedAt'),
      ],
      rowActionsBuilder: _merchantActions,
    );
  }
}

List<Widget> _merchantActions(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final service = AdminActionService();

  Future<void> setStatus(String status, String label) async {
    final reason = await askAdminReason(
      context,
      title: label,
      actionLabel: label,
      message: 'This updates merchant verification and writes an audit log.',
    );
    if (reason == null) return;
    try {
      await service.updateWithAudit(
        targetRef: doc.reference,
        data: {
          'status': status,
        },
        action: 'merchant_verification_$status',
        targetType: 'merchant_verifications',
        reason: reason,
      );
      if (!context.mounted) return;
      showAdminSnack(context, 'Merchant marked $status.');
    } catch (error) {
      if (!context.mounted) return;
      showAdminSnack(context, 'Action failed: $error', isError: true);
    }
  }

  return [
    FilledButton.tonalIcon(
      onPressed: () => setStatus('approved', 'Approve merchant'),
      icon: const Icon(Icons.check),
      label: const Text('Approve'),
    ),
    OutlinedButton.icon(
      onPressed: () => setStatus('rejected', 'Reject merchant'),
      icon: const Icon(Icons.close),
      label: const Text('Reject'),
    ),
    OutlinedButton.icon(
      onPressed: () => setStatus('suspended', 'Suspend merchant'),
      icon: const Icon(Icons.block),
      label: const Text('Suspend'),
    ),
  ];
}
