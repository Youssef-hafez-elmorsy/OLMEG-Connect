import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/actions/admin_action_service.dart';
import '../../core/widgets/admin_tokens.dart';
import '../shared/admin_action_dialogs.dart';
import '../shared/admin_collection_table_page.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Notifications',
      description:
          'Create, monitor, cancel, and audit admin-approved campaigns.',
      icon: Icons.campaign_outlined,
      collectionName: 'admin_notifications',
      headerActions: [
        Builder(
          builder: (context) {
            return FilledButton.icon(
              onPressed: () => _sendNotification(context),
              icon: const Icon(Icons.send),
              label: const Text('Send notification'),
            );
          },
        ),
      ],
      columns: [
        AdminTableColumn.field('Title', 'title'),
        AdminTableColumn.field('Message', 'body'),
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Audience', 'audience'),
        AdminTableColumn.field('Created By', 'createdBy'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: _notificationActions,
    );
  }
}

Future<void> _sendNotification(BuildContext context) async {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final reasonController = TextEditingController();
  var audience = 'all';
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<_NotificationDraft>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(AdminSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminRadius.xl),
            ),
            child: Form(
              key: formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: AdminGradients.command,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AdminRadius.xl),
                        ),
                      ),
                      padding: const EdgeInsets.all(AdminSpacing.lg),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.campaign_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: AdminSpacing.md),
                          Expanded(
                            child: Text(
                              'Send notification',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AdminSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: audience,
                            decoration: const InputDecoration(
                              labelText: 'Audience',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All users'),
                              ),
                              DropdownMenuItem(
                                value: 'buyers',
                                child: Text('Buyers'),
                              ),
                              DropdownMenuItem(
                                value: 'merchants',
                                child: Text('Merchants'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => audience = value ?? 'all');
                            },
                          ),
                          const SizedBox(height: AdminSpacing.md),
                          TextFormField(
                            controller: titleController,
                            decoration:
                                const InputDecoration(labelText: 'Title'),
                            validator: _required,
                          ),
                          const SizedBox(height: AdminSpacing.md),
                          TextFormField(
                            controller: bodyController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Message',
                              alignLabelWithHint: true,
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: AdminSpacing.md),
                          TextFormField(
                            controller: reasonController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Audit reason',
                              alignLabelWithHint: true,
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: AdminSpacing.md),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AdminColors.warningSoft,
                              borderRadius:
                                  BorderRadius.circular(AdminRadius.md),
                            ),
                            padding: const EdgeInsets.all(AdminSpacing.md),
                            child: const Text(
                              'Fanout is capped at 25 users from the selected audience. For larger campaigns, use staged rollout after monitoring delivery health.',
                            ),
                          ),
                          const SizedBox(height: AdminSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: AdminSpacing.sm),
                              FilledButton.icon(
                                onPressed: () {
                                  if (!formKey.currentState!.validate()) return;
                                  Navigator.pop(
                                    context,
                                    _NotificationDraft(
                                      title: titleController.text.trim(),
                                      body: bodyController.text.trim(),
                                      audience: audience,
                                      reason: reasonController.text.trim(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.send),
                                label: const Text('Send'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  if (result == null) return;
  try {
    final count = await AdminActionService().createNotificationCampaign(
      title: result.title,
      body: result.body,
      audience: result.audience,
      reason: result.reason,
    );
    if (!context.mounted) return;
    showAdminSnack(context, 'Notification sent to $count user(s).');
  } catch (error) {
    if (!context.mounted) return;
    showAdminSnack(context, 'Notification failed: $error', isError: true);
  }
}

List<Widget> _notificationActions(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final service = AdminActionService();
  return [
    OutlinedButton.icon(
      onPressed: () async {
        final reason = await askAdminReason(
          context,
          title: 'Cancel notification',
          actionLabel: 'Cancel',
          message: 'This marks the campaign as cancelled.',
        );
        if (reason == null) return;
        try {
          await service.updateWithAudit(
            targetRef: doc.reference,
            data: {'status': 'cancelled'},
            action: 'notification_cancelled',
            targetType: 'admin_notifications',
            reason: reason,
          );
          if (!context.mounted) return;
          showAdminSnack(context, 'Notification cancelled.');
        } catch (error) {
          if (!context.mounted) return;
          showAdminSnack(context, 'Action failed: $error', isError: true);
        }
      },
      icon: const Icon(Icons.cancel_outlined),
      label: const Text('Cancel'),
    ),
    OutlinedButton.icon(
      onPressed: () async {
        final reason = await askAdminReason(
          context,
          title: 'Delete notification record',
          actionLabel: 'Delete',
          message: 'This deletes the campaign record from admin_notifications.',
        );
        if (reason == null) return;
        try {
          await service.deleteWithAudit(
            targetRef: doc.reference,
            action: 'notification_deleted',
            targetType: 'admin_notifications',
            reason: reason,
          );
          if (!context.mounted) return;
          showAdminSnack(context, 'Notification deleted.');
        } catch (error) {
          if (!context.mounted) return;
          showAdminSnack(context, 'Action failed: $error', isError: true);
        }
      },
      icon: const Icon(Icons.delete_outline),
      label: const Text('Delete'),
    ),
  ];
}

String? _required(String? value) {
  return (value ?? '').trim().isEmpty ? 'Required' : null;
}

class _NotificationDraft {
  final String title;
  final String body;
  final String audience;
  final String reason;

  const _NotificationDraft({
    required this.title,
    required this.body,
    required this.audience,
    required this.reason,
  });
}
