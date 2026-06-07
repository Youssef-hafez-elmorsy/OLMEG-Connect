import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('admin v2 production hardening', () {
    late String rules;
    late String indexes;
    late String commands;
    late String main;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
      indexes = File('firestore.indexes.json').readAsStringSync();
      commands = File('functions/adminCommands.js').readAsStringSync();
      main = File('apps/admin_web/lib/main.dart').readAsStringSync();
    });

    test('v2 protected collections are explicitly ruled and default-denied',
        () {
      for (final collection in [
        'support_tickets',
        'refunds',
        'promotions',
        'risk_cases',
        'ai_moderation_reviews',
        'admin_summaries',
        'admin_settings',
      ]) {
        expect(rules, contains('match /$collection/'));
      }
      expect(rules, contains('match /{document=**}'));
      expect(rules, contains('allow read, write: if false'));
    });

    test('v2 queue indexes are documented', () {
      for (final collection in [
        'support_tickets',
        'refunds',
        'payments',
        'risk_cases',
        'ai_moderation_reviews',
        'admin_notifications',
        'admin_roles',
        'promotions',
      ]) {
        expect(indexes, contains('"collectionGroup": "$collection"'));
      }
    });

    test('sensitive v2 workflows use backend commands and audit', () {
      expect(commands, contains('adminUpdateOperationalRecord'));
      expect(commands, contains('OPERATIONAL_ACTIONS'));
      expect(commands, contains("db.collection('audit_logs').doc()"));
      expect(commands, contains('immutable: true'));
    });

    test('admin web installs production error monitoring hook', () {
      expect(main, contains('AdminErrorReporter.install'));
      expect(main, contains('runGuarded'));
    });
  });
}
