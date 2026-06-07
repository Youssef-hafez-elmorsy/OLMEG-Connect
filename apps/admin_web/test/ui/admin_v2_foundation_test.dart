import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('admin operations v2 foundation', () {
    test('shared admin components exist for production pages', () {
      const files = [
        'lib/core/widgets/admin_scaffold.dart',
        'lib/core/widgets/admin_data_grid.dart',
        'lib/core/widgets/admin_detail_drawer.dart',
        'lib/core/widgets/admin_metric_card.dart',
        'lib/core/widgets/admin_status_badge.dart',
        'lib/features/shared/admin_action_dialogs.dart',
      ];

      for (final path in files) {
        expect(File(path).existsSync(), isTrue, reason: '$path is missing');
      }
    });

    test('admin shell has top search and grouped navigation', () {
      final shell = File('lib/auth/admin_auth_gate.dart').readAsStringSync();
      final routes = File('lib/core/rbac/admin_access.dart').readAsStringSync();

      expect(shell, contains('_AdminTopBar'));
      expect(shell, contains('Global search'));
      expect(shell, contains('_NavigationGroup'));
      expect(shell, contains('ExpansionTile'));
      expect(shell, contains('_NavSectionLabel'));
      expect(shell, contains('_TopBarNavChip'));
      expect(shell, contains('_firstReachablePath'));
      expect(shell, contains('PUBLIC_APP_URL'));
      expect(shell, contains('_openPublicApp'));
      expect(shell, contains('Public app'));
      expect(shell, isNot(contains('onPressed: () {}')));
      expect(routes, contains('Operations'));
      expect(routes, contains('Governance'));
    });

    test('admin collection pages use v2 scaffold and grid', () {
      final page = File('lib/features/shared/admin_collection_table_page.dart')
          .readAsStringSync();

      expect(page, contains('AdminScaffold'));
      expect(page, contains('AdminDataGrid'));
      expect(page, contains('AdminDetailDrawer'));
      expect(page, contains('Backend commands'));
    });
  });
}
