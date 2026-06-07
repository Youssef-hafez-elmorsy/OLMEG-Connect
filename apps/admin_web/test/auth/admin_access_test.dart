import 'package:flutter_test/flutter_test.dart';
import 'package:olmeg_admin_web/core/rbac/admin_access.dart';
import 'package:olmeg_admin_web/core/rbac/admin_roles.dart';

void main() {
  group('admin claim parsing', () {
    test('parses direct role claim', () {
      expect(roleFromClaims({'role': 'admin'}), AdminRole.admin);
      expect(roleFromClaims({'role': 'super_admin'}), AdminRole.superAdmin);
    });

    test('parses roles list claim', () {
      expect(
          roleFromClaims({
            'roles': ['support']
          }),
          AdminRole.support);
    });

    test('legacy admin boolean maps to admin role', () {
      expect(roleFromClaims({'admin': true}), AdminRole.admin);
    });

    test('missing or unknown claim is denied', () {
      expect(roleFromClaims({}), isNull);
      expect(roleFromClaims({'role': 'buyer'}), isNull);
    });

    test('first allowed path matches role capability', () {
      expect(firstAllowedPath(AdminRole.admin), '/dashboard');
      expect(firstAllowedPath(AdminRole.moderator), '/catalog/products');
      expect(firstAllowedPath(AdminRole.support), '/reports');
      expect(firstAllowedPath(null), '/access-denied');
    });
  });
}
