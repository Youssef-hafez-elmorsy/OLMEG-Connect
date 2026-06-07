import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bootstrap runbook documents one-time super admin creation', () {
    final source = File('docs/admin-bootstrap.md').readAsStringSync();
    expect(source, contains('one-time'));
    expect(source, contains('super_admin'));
    expect(source, contains('Firebase Admin SDK'));
  });
}
