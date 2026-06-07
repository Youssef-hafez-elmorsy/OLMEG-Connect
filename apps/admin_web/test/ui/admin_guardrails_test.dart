import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('admin guardrail copy', () {
    test('does not show generic protected collection fallback', () {
      final tablePageSource =
          File('lib/features/shared/admin_collection_table_page.dart')
              .readAsStringSync();

      expect(tablePageSource, isNot(contains('protected admin collection')));
      expect(tablePageSource, contains('required this.collectionName'));
      expect(tablePageSource, contains('Reads are capped'));
      expect(tablePageSource, contains('Backend commands'));
    });

    test('every admin table page declares a concrete protected data source',
        () {
      final featureFiles = Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_screen.dart'))
          .where((file) {
        return file.readAsStringSync().contains('AdminCollectionTablePage(');
      }).toList();

      expect(featureFiles, isNotEmpty);
      for (final file in featureFiles) {
        final source = file.readAsStringSync();
        expect(
          source,
          contains('collectionName:'),
          reason: '${file.path} must declare the protected data source.',
        );
      }
    });

    test('admin screens render real tables or dashboard metrics', () {
      final featureFiles = Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_screen.dart'))
          .toList();

      final sources = featureFiles.map((file) => file.readAsStringSync());
      expect(
        sources.any((source) => source.contains('AdminPage(')),
        isFalse,
        reason: 'Placeholder AdminPage shells should not be used.',
      );
      expect(
        sources.where((source) {
          return source.contains('AdminCollectionTablePage(');
        }).length,
        greaterThanOrEqualTo(6),
      );
      expect(
        sources.any((source) => source.contains('_DashboardMetricsGrid')),
        isTrue,
      );
    });

    test('operational pages expose admin controls with audit-backed service',
        () {
      final actionService =
          File('lib/core/actions/admin_action_service.dart').readAsStringSync();
      final users = File('lib/features/users/users_management_screen.dart')
          .readAsStringSync();
      final notifications = File(
        'lib/features/notifications/admin_notifications_screen.dart',
      ).readAsStringSync();
      final moderation = File(
        'lib/features/moderation/product_moderation_screen.dart',
      ).readAsStringSync();
      final merchants = File(
        'lib/features/merchants/merchant_verification_screen.dart',
      ).readAsStringSync();
      final reports =
          File('lib/features/reports/reports_screen.dart').readAsStringSync();

      expect(actionService, contains('FirebaseFunctions'));
      expect(actionService, contains('httpsCallable'));
      expect(actionService, contains('commandForAction'));
      expect(actionService, contains('adminCreateNotificationCampaign'));
      expect(users, contains('Block user'));
      expect(users, contains('Soft delete user'));
      expect(notifications, contains('Send notification'));
      expect(notifications, contains('createNotificationCampaign'));
      expect(moderation, contains('Approve product'));
      expect(merchants, contains('Approve merchant'));
      expect(reports, contains('Resolve report'));
    });

    test('product operations expose photo evidence columns', () {
      final operations = File(
        'lib/features/operations/admin_operations_screens.dart',
      ).readAsStringSync();
      final moderation = File(
        'lib/features/moderation/product_moderation_screen.dart',
      ).readAsStringSync();

      expect(operations, contains('AdminTableColumn.image'));
      expect(operations, contains("'images'"));
      expect(moderation, contains('AdminTableColumn.image'));
      expect(moderation, contains("'productImageUrl'"));
    });

    test('core admin queues expose visible server-side filter options', () {
      final tablePageSource =
          File('lib/features/shared/admin_collection_table_page.dart')
              .readAsStringSync();
      final users = File('lib/features/users/users_management_screen.dart')
          .readAsStringSync();
      final moderation = File(
        'lib/features/moderation/product_moderation_screen.dart',
      ).readAsStringSync();
      final merchants = File(
        'lib/features/merchants/merchant_verification_screen.dart',
      ).readAsStringSync();

      expect(tablePageSource, contains('AdminServerFilterOption'));
      expect(tablePageSource, contains('FilterChip'));
      expect(tablePageSource, contains('selectedServerFilter'));
      expect(users, contains('serverFilterOptions'));
      expect(users, contains("AdminServerFilter.equals('accountStatus'"));
      expect(
          moderation, contains("AdminServerFilter.equals('moderationStatus'"));
      expect(merchants, contains("AdminServerFilter.equals('status'"));
    });
  });
}
