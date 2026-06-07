import 'package:flutter_test/flutter_test.dart';
import 'package:olmeg_admin_web/core/rbac/admin_action_policy.dart';
import 'package:olmeg_admin_web/core/rbac/admin_roles.dart';

void main() {
  group('admin action policy', () {
    test('covers every declared action with a capability and reason rule', () {
      expect(adminActionPolicies, isNotEmpty);

      for (final policy in adminActionPolicies) {
        expect(policy.id, isNotEmpty);
        expect(policy.label, isNotEmpty);
        expect(policy.roles, isNotEmpty);
      }

      expect(
        adminActionPolicies.where((policy) => policy.reasonRequired),
        isNotEmpty,
      );
    });

    test('moderators can act only in moderation and reports areas', () {
      final moderatorActions = AdminActionArea.values
          .expand(
              (area) => adminActionsForArea(area, role: AdminRole.moderator))
          .map((policy) => policy.id)
          .toSet();

      expect(moderatorActions, contains('product_moderation_approved'));
      expect(moderatorActions, contains('report_resolved'));
      expect(moderatorActions, isNot(contains('user_banned')));
      expect(moderatorActions, isNot(contains('payment_mark_reviewed')));
      expect(moderatorActions, isNot(contains('staff_role_assigned')));
    });

    test('support can resolve reports but cannot moderate products', () {
      expect(
        adminActionsForArea(AdminActionArea.reports, role: AdminRole.support)
            .map((policy) => policy.id),
        contains('report_resolved'),
      );
      expect(
        adminActionsForArea(
          AdminActionArea.productModeration,
          role: AdminRole.support,
        ),
        isEmpty,
      );
    });

    test('super admins are the only role with staff and audit actions', () {
      for (final role
          in AdminRole.values.where((role) => role != AdminRole.superAdmin)) {
        expect(adminActionsForArea(AdminActionArea.staff, role: role), isEmpty);
        expect(adminActionsForArea(AdminActionArea.auditLogs, role: role),
            isEmpty);
      }

      expect(
        adminActionsForArea(AdminActionArea.staff, role: AdminRole.superAdmin),
        isNotEmpty,
      );
      expect(
        adminActionsForArea(
          AdminActionArea.auditLogs,
          role: AdminRole.superAdmin,
        ),
        isNotEmpty,
      );
    });
  });
}
