import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('admin backend command layer', () {
    late String commands;
    late String functionsIndex;
    late String actionClient;

    setUpAll(() {
      commands = File('functions/adminCommands.js').readAsStringSync();
      functionsIndex = File('functions/index.js').readAsStringSync();
      actionClient = File(
        'apps/admin_web/lib/core/actions/admin_action_service.dart',
      ).readAsStringSync();
    });

    test('functions expose trusted commands for sensitive workflows', () {
      for (final command in [
        'adminBlockUser',
        'adminUnblockUser',
        'adminSoftDeleteUser',
        'adminApproveMerchant',
        'adminRejectMerchant',
        'adminSuspendMerchant',
        'adminApproveProduct',
        'adminRejectProduct',
        'adminHideProduct',
        'adminEscalateProduct',
        'adminResolveReport',
        'adminDismissReport',
        'adminEscalateReport',
        'adminCreateNotificationCampaign',
        'adminCancelNotificationCampaign',
        'adminAssignStaffRole',
        'adminDisableStaff',
        'adminUpdateOperationalRecord',
        'adminRefreshAdminSummary',
      ]) {
        expect(commands, contains(command));
      }
    });

    test('commands enforce role, reason, and immutable audit logs', () {
      expect(commands, contains('assertAllowed'));
      expect(commands, contains('requiredString(data.reason'));
      expect(commands, contains("db.collection('audit_logs').doc()"));
      expect(commands, contains('schemaVersion: 1'));
      expect(commands, contains('immutable: true'));
      expect(commands, contains('FieldValue.serverTimestamp()'));
    });

    test('staff commands update claims and protect the last super admin', () {
      expect(commands, contains('setCustomUserClaims'));
      expect(commands, contains('revokeRefreshTokens'));
      expect(commands, contains('assertLastSuperAdminSafe'));
      expect(commands, contains('last active super_admin'));
      expect(commands, contains('admin_role_changed'));
      expect(commands, contains('admin_staff_disabled'));
    });

    test('generic operational command is allowlisted and audited', () {
      expect(commands, contains('OPERATIONAL_COLLECTIONS'));
      expect(commands, contains('OPERATIONAL_ACTIONS'));
      expect(commands, contains('runUpdateOperationalRecord'));
      expect(commands, contains('adminUpdateOperationalRecord'));
      expect(commands, contains('This operational action is not allowlisted'));
    });

    test('admin web command client uses callable functions', () {
      expect(actionClient, contains('FirebaseFunctions'));
      expect(actionClient, contains('httpsCallable'));
      expect(actionClient, contains('adminCreateNotificationCampaign'));
      expect(actionClient, contains('adminUpdateOperationalRecord'));
      expect(actionClient, isNot(contains("collection('audit_logs').add")));
    });

    test('legacy campaign callables require admin claims', () {
      expect(functionsIndex, contains('function requireAdminCaller(context)'));
      expect(functionsIndex, contains('exports.sendWelcomeCampaign'));
      expect(functionsIndex, contains('exports.blastCampaign'));
      expect(
        functionsIndex,
        contains(
            'exports.sendWelcomeCampaign = functions.https.onCall(async (data, context) => {\n  requireAdminCaller(context);'),
      );
      expect(
        functionsIndex,
        contains(
            'exports.blastCampaign = functions.https.onCall(async (data, context) => {\n  requireAdminCaller(context);'),
      );
    });

    test('paymob checkout verifies client-created order pricing server-side',
        () {
      expect(functionsIndex, contains('verifiedCheckoutOrder(order)'));
      expect(
          functionsIndex, contains("db.collection('products').doc(id).get()"));
      expect(functionsIndex,
          contains('Order total does not match current product pricing'));
      expect(
          functionsIndex,
          contains(
              'const checkoutOrder = await verifiedCheckoutOrder(order);'));
    });
  });
}
