import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('admin Firestore rules static guards', () {
    late String rules;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
    });

    test('rules define admin role helpers', () {
      expect(rules, contains('claimRole()'));
      expect(rules, contains('isModerator()'));
      expect(rules, contains('isSupport()'));
      expect(rules, contains('isSuperAdmin()'));
    });

    test('admin status is trusted from custom claims only', () {
      expect(rules, isNot(contains('userDoc().data.isAdmin == true')));
      expect(rules, contains("request.auth.token.role == 'admin'"));
      expect(rules, contains("request.auth.token.role == 'super_admin'"));
    });

    test('rules protect admin role metadata and backend-only audit logs', () {
      expect(rules, contains('match /admin_roles/{userId}'));
      expect(rules, contains('match /audit_logs/{auditId}'));
      expect(rules, contains('allow create, update, delete: if false'));
    });

    test('rules deny by default instead of using a signed-in fallback', () {
      expect(rules, contains('match /{document=**}'));
      expect(rules, contains('allow read, write: if false'));
      expect(
          rules, isNot(contains('&& !isReservedAdminCollection(collection)')));
    });

    test('audit logs are immutable and backend-only from the client boundary',
        () {
      expect(rules, contains('match /audit_logs/{auditId}'));
      expect(rules, contains('allow read: if isSuperAdmin();'));
      expect(rules, contains('allow create, update, delete: if false;'));
    });

    test('backend rules mirror moderator and support route access', () {
      expect(rules, contains('allow update: if isModerator();'));
      expect(rules, contains('allow update: if isModerator() || isSupport();'));
      expect(
          rules,
          contains(
              'allow create, update, delete: if isAdmin() || isSuperAdmin();'));
      expect(rules, contains('match /support_tickets/{ticketId}'));
      expect(rules, contains('match /refunds/{refundId}'));
      expect(rules, contains('match /risk_cases/{caseId}'));
    });

    test('rules deny client role escalation except super admin path', () {
      expect(rules, contains('allow write: if isSuperAdmin()'));
      expect(rules, contains('role assignment'));
    });

    test('owners cannot self-approve merchant or admin-sensitive user fields',
        () {
      expect(rules, contains('ownerUserUpdateIsSafe()'));
      expect(rules, contains("'merchantVerificationStatus'"));
      expect(rules, contains("'isApprovedMerchant'"));
      expect(rules, contains("'adminStaff'"));
      expect(
        rules,
        contains(
            'allow update: if isAdmin() || (isOwner(userId) && ownerUserUpdateIsSafe());'),
      );
    });

    test('order writes keep payment state backend controlled', () {
      expect(rules, contains('validOrderCreate()'));
      expect(
          rules, contains("request.resource.data.status == 'pendingPayment'"));
      expect(
          rules,
          contains(
              "request.resource.data.payment.status in ['pending', 'notStarted']"));
      expect(rules, contains('validBuyerOrderUpdate()'));
      expect(rules, contains('validSellerOrderUpdate()'));
      expect(
        rules,
        contains(
            'allow update: if isAdmin() || validBuyerOrderUpdate() || validSellerOrderUpdate();'),
      );
    });
  });
}
