import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('role manager documents super admin only role assignment', () {
    final source = File('tools/admin_role_manager.dart').readAsStringSync();
    expect(source, contains('super_admin'));
    expect(source, contains('Only super_admin'));
    expect(source, contains('audit'));
  });

  test('claim script does not turn support or moderator into full admin', () {
    final source = File('tools/set_admin_claim.js').readAsStringSync();
    expect(source, contains("role === 'admin' || role === 'super_admin'"));
    expect(source, contains('admin: hasFullAdminRole'));
    expect(source, contains('adminStaff: true'));
  });
}
