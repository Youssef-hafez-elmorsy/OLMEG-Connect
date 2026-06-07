import 'package:flutter/material.dart';

import '../shared/admin_collection_table_page.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Audit Logs',
      description:
          'Immutable privileged action history for super_admin review.',
      icon: Icons.history_edu_outlined,
      collectionName: 'audit_logs',
      headerActions: [
        Tooltip(
          message:
              'CSV export must be implemented as a backend job before release.',
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export planned'),
          ),
        ),
      ],
      columns: [
        AdminTableColumn.field('Action', 'action'),
        AdminTableColumn.field('Actor', 'actorUid'),
        AdminTableColumn.field('Role', 'actorRole'),
        AdminTableColumn.field('Target', 'targetId'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
    );
  }
}
