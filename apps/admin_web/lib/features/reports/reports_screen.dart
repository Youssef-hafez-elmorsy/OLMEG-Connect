import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/actions/admin_action_service.dart';
import '../shared/admin_action_dialogs.dart';
import '../shared/admin_collection_table_page.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Reports',
      description: 'Support and moderation queues for reported content.',
      icon: Icons.report_outlined,
      collectionName: 'reports',
      columns: [
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Type', 'targetType'),
        AdminTableColumn.field('Reporter', 'reporterId'),
        AdminTableColumn.field('Target', 'targetId'),
        AdminTableColumn.field('Conversation', 'conversationId'),
        AdminTableColumn(
          label: 'Evidence',
          width: 280,
          value: (data) {
            final evidence = data['evidenceSnapshot'];
            if (evidence is! Map) return '-';
            final message = evidence['message'];
            if (message is Map && message['content'] != null) {
              return message['content'].toString();
            }
            return evidence['latestMessagePreview']?.toString() ??
                evidence['productTitle']?.toString() ??
                '-';
          },
        ),
        AdminTableColumn.field('Reason', 'reason'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: _reportActions,
    );
  }
}

List<Widget> _reportActions(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final service = AdminActionService();

  Future<void> setStatus(String status, String label) async {
    final reason = await askAdminReason(
      context,
      title: label,
      actionLabel: label,
      message: 'This updates the report and creates an immutable audit log.',
    );
    if (reason == null) return;
    try {
      await service.updateWithAudit(
        targetRef: doc.reference,
        data: {'status': status},
        action: 'report_$status',
        targetType: 'reports',
        reason: reason,
        metadata: {'reportId': doc.id},
      );
      if (!context.mounted) return;
      showAdminSnack(context, 'Report marked $status.');
    } catch (error) {
      if (!context.mounted) return;
      showAdminSnack(context, 'Action failed: $error', isError: true);
    }
  }

  return [
    FilledButton.tonalIcon(
      onPressed: () => setStatus('resolved', 'Resolve report'),
      icon: const Icon(Icons.check),
      label: const Text('Resolve'),
    ),
    OutlinedButton.icon(
      onPressed: () => setStatus('dismissed', 'Dismiss report'),
      icon: const Icon(Icons.close),
      label: const Text('Dismiss'),
    ),
    OutlinedButton.icon(
      onPressed: () => setStatus('escalated', 'Escalate report'),
      icon: const Icon(Icons.priority_high),
      label: const Text('Escalate'),
    ),
  ];
}
