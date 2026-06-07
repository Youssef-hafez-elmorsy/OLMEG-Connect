import 'package:flutter_test/flutter_test.dart';
import 'package:olmeg_admin_web/core/rbac/admin_access.dart';
import 'package:olmeg_admin_web/core/rbac/admin_roles.dart';

void main() {
  group('admin route role matrix', () {
    test('non-admin cannot access protected admin routes', () {
      for (final route in adminRoutes) {
        expect(canAccessPath(null, route.path), isFalse);
      }
    });

    test('admin can access dashboard and operations pages', () {
      expect(canAccessPath(AdminRole.admin, '/dashboard'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/search'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/users'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/users/demo'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/catalog/products'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/orders'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/payments'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/payments/paymob'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/support/tickets'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/risk'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/analytics'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/moderation/products'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/reports'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/merchants'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/notifications'), isTrue);
      expect(canAccessPath(AdminRole.admin, '/audit-logs'), isFalse);
      expect(canAccessPath(AdminRole.admin, '/staff'), isFalse);
    });

    test('moderator can access moderation and reports only', () {
      expect(canAccessPath(AdminRole.moderator, '/search'), isTrue);
      expect(
          canAccessPath(AdminRole.moderator, '/moderation/products'), isTrue);
      expect(canAccessPath(AdminRole.moderator, '/moderation/reviews'), isTrue);
      expect(canAccessPath(AdminRole.moderator, '/catalog/products'), isTrue);
      expect(canAccessPath(AdminRole.moderator, '/reports'), isTrue);
      expect(canAccessPath(AdminRole.moderator, '/dashboard'), isFalse);
      expect(canAccessPath(AdminRole.moderator, '/users'), isFalse);
      expect(canAccessPath(AdminRole.moderator, '/merchants'), isFalse);
      expect(canAccessPath(AdminRole.moderator, '/notifications'), isFalse);
      expect(canAccessPath(AdminRole.moderator, '/audit-logs'), isFalse);
    });

    test('support can access reports and support workflows only', () {
      expect(canAccessPath(AdminRole.support, '/search'), isTrue);
      expect(canAccessPath(AdminRole.support, '/reports'), isTrue);
      expect(canAccessPath(AdminRole.support, '/reports/demo'), isTrue);
      expect(canAccessPath(AdminRole.support, '/users/demo'), isTrue);
      expect(canAccessPath(AdminRole.support, '/orders'), isTrue);
      expect(canAccessPath(AdminRole.support, '/refunds'), isTrue);
      expect(canAccessPath(AdminRole.support, '/support/tickets'), isTrue);
      expect(canAccessPath(AdminRole.support, '/moderation/products'), isFalse);
      expect(canAccessPath(AdminRole.support, '/dashboard'), isFalse);
      expect(canAccessPath(AdminRole.support, '/users'), isFalse);
      expect(canAccessPath(AdminRole.support, '/merchants'), isFalse);
      expect(canAccessPath(AdminRole.support, '/notifications'), isFalse);
      expect(canAccessPath(AdminRole.support, '/audit-logs'), isFalse);
      expect(canAccessPath(AdminRole.support, '/payments'), isFalse);
      expect(canAccessPath(AdminRole.support, '/payments/paymob'), isFalse);
    });

    test('super admin can access all admin routes', () {
      for (final route in adminRoutes) {
        expect(canAccessPath(AdminRole.superAdmin, route.path), isTrue);
      }
    });
  });
}
