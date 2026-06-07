import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/actions/admin_action_service.dart';
import '../../core/widgets/admin_data_grid.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/widgets/admin_status_badge.dart';
import '../../core/widgets/admin_tokens.dart';
import '../shared/admin_action_dialogs.dart';

class AdminDocumentDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String collectionName;
  final String documentId;
  final List<AdminRelatedPanel> relatedPanels;
  final bool allowNote;

  const AdminDocumentDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.collectionName,
    required this.documentId,
    this.relatedPanels = const [],
    this.allowNote = true,
  });

  @override
  Widget build(BuildContext context) {
    final ref =
        FirebaseFirestore.instance.collection(collectionName).doc(documentId);

    return AdminScaffold(
      title: title,
      description: description,
      icon: icon,
      actions: [
        if (allowNote)
          OutlinedButton.icon(
            onPressed: () => _addNote(context, ref),
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('Add note'),
          ),
      ],
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _DetailStateCard(
              icon: Icons.lock_outline,
              title: 'Detail unavailable',
              message: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const _DetailStateCard(
              icon: Icons.search_off_outlined,
              title: 'Record not found',
              message: 'This document does not exist or is not visible.',
            );
          }

          final data = snapshot.data!.data() ?? {};
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AdminBreakpoints.wide;
              final overview = _DetailOverviewCard(
                documentId: documentId,
                collectionName: collectionName,
                data: data,
              );
              final fields = _FieldsPanel(data: data);
              final related = _RelatedPanels(
                documentId: documentId,
                panels: relatedPanels,
              );
              final auditHistory = _AuditHistoryPanel(documentId: documentId);

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 390, child: overview),
                    const SizedBox(width: AdminSpacing.lg),
                    Expanded(
                      child: ListView(
                        children: [
                          fields,
                          const SizedBox(height: AdminSpacing.lg),
                          related,
                          const SizedBox(height: AdminSpacing.lg),
                          auditHistory,
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView(
                children: [
                  overview,
                  const SizedBox(height: AdminSpacing.lg),
                  fields,
                  const SizedBox(height: AdminSpacing.lg),
                  related,
                  const SizedBox(height: AdminSpacing.lg),
                  auditHistory,
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addNote(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final reason = await askAdminReason(
      context,
      title: 'Add internal note',
      actionLabel: 'Save note',
      message: 'This note is saved through a trusted command and audited.',
    );
    if (reason == null) return;
    try {
      await AdminActionService().updateWithAudit(
        targetRef: ref,
        data: {
          'lastAdminNote': reason,
          'lastAdminNoteAt': DateTime.now().toIso8601String(),
        },
        action: '${collectionName}_note_added',
        targetType: collectionName,
        reason: reason,
      );
      if (!context.mounted) return;
      showAdminSnack(context, 'Internal note saved.');
    } catch (error) {
      if (!context.mounted) return;
      showAdminSnack(context, 'Note failed: $error', isError: true);
    }
  }
}

class _AuditHistoryPanel extends StatelessWidget {
  final String documentId;

  const _AuditHistoryPanel({required this.documentId});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('audit_logs')
        .where('targetId', isEqualTo: documentId)
        .orderBy('createdAt', descending: true)
        .limit(10);

    return _Panel(
      title: 'Audit history',
      icon: Icons.history_edu_outlined,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Audit history is visible to authorized roles only: '
              '${snapshot.error}',
              style: const TextStyle(color: AdminColors.muted),
            );
          }
          if (!snapshot.hasData) {
            return const LinearProgressIndicator();
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Text(
              'No immutable audit entries are linked to this record yet.',
              style: TextStyle(color: AdminColors.muted),
            );
          }
          return Column(
            children: [
              for (final doc in docs)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_outlined),
                  title: Text(adminCellValue(doc.data()['action'])),
                  subtitle: Text(
                    '${adminCellValue(doc.data()['actorRole'])} '
                    'by ${adminCellValue(doc.data()['actorUid'])}',
                  ),
                  trailing: Text(adminCellValue(doc.data()['createdAt'])),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AdminRelatedPanel {
  final String title;
  final String collectionName;
  final String fieldName;
  final IconData icon;

  const AdminRelatedPanel({
    required this.title,
    required this.collectionName,
    required this.fieldName,
    required this.icon,
  });
}

class _DetailOverviewCard extends StatelessWidget {
  final String documentId;
  final String collectionName;
  final Map<String, dynamic> data;

  const _DetailOverviewCard({
    required this.documentId,
    required this.collectionName,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusFrom(data);
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminStatusBadge(
            label: status,
            tone: adminToneForStatus(status),
            icon: Icons.circle,
          ),
          const SizedBox(height: AdminSpacing.lg),
          SelectableText(
            documentId,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AdminSpacing.sm),
          Text(
            collectionName,
            style: const TextStyle(color: AdminColors.muted),
          ),
          const SizedBox(height: AdminSpacing.lg),
          const _DetailRuleLine('Reads are protected by Firestore Rules.'),
          const _DetailRuleLine(
              'Sensitive writes go through backend commands.'),
          const _DetailRuleLine('Every operator note is audit-linked.'),
        ],
      ),
    );
  }
}

class _FieldsPanel extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FieldsPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Record fields',
      icon: Icons.dataset_outlined,
      child: Column(
        children: [
          for (final entry in data.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(child: SelectableText(adminCellValue(entry.value))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RelatedPanels extends StatelessWidget {
  final String documentId;
  final List<AdminRelatedPanel> panels;

  const _RelatedPanels({
    required this.documentId,
    required this.panels,
  });

  @override
  Widget build(BuildContext context) {
    if (panels.isEmpty) {
      return const _Panel(
        title: 'Timeline',
        icon: Icons.timeline_outlined,
        child: Text(
          'No related panels configured for this record yet.',
          style: TextStyle(color: AdminColors.muted),
        ),
      );
    }

    return Column(
      children: [
        for (final panel in panels) ...[
          _RelatedPanel(documentId: documentId, panel: panel),
          const SizedBox(height: AdminSpacing.lg),
        ],
      ],
    );
  }
}

class _RelatedPanel extends StatelessWidget {
  final String documentId;
  final AdminRelatedPanel panel;

  const _RelatedPanel({
    required this.documentId,
    required this.panel,
  });

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection(panel.collectionName)
        .where(panel.fieldName, isEqualTo: documentId)
        .limit(10);

    return _Panel(
      title: panel.title,
      icon: panel.icon,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Unable to load: ${snapshot.error}',
              style: const TextStyle(color: AdminColors.danger),
            );
          }
          if (!snapshot.hasData) {
            return const LinearProgressIndicator();
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Text(
              'No linked records in this capped panel.',
              style: TextStyle(color: AdminColors.muted),
            );
          }
          return Column(
            children: [
              for (final doc in docs)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link),
                  title: Text(doc.id),
                  subtitle: Text(adminCellValue(doc.data())),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AdminColors.primary),
              const SizedBox(width: AdminSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _DetailStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _DetailStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: AdminColors.card,
          borderRadius: BorderRadius.circular(AdminRadius.xl),
          border: Border.all(color: AdminColors.border),
          boxShadow: AdminShadows.card,
        ),
        padding: const EdgeInsets.all(AdminSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AdminColors.primary),
            const SizedBox(height: AdminSpacing.md),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AdminSpacing.sm),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DetailRuleLine extends StatelessWidget {
  final String text;

  const _DetailRuleLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AdminColors.success, size: 18),
          const SizedBox(width: AdminSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

String _statusFrom(Map<String, dynamic> data) {
  for (final key in [
    'status',
    'accountStatus',
    'moderationStatus',
    'paymentStatus',
    'riskStatus',
  ]) {
    final value = data[key];
    if (value != null) return value.toString();
  }
  return 'Active';
}
