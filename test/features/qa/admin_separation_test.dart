import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('public app admin separation', () {
    test('public router does not register admin routes', () {
      final source = File('lib/core/router/app_router.dart').readAsStringSync();
      expect(source, isNot(contains("path: '/admin")));
      expect(source, isNot(contains("startsWith('/admin/")));
      expect(source, isNot(contains('AdminDashboardScreen')));
    });

    test('public profile has no admin menu entry points', () {
      final source = File(
        'lib/features/profile/presentation/screens/profile_screen.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('Admin Dashboard')));
      expect(source, isNot(contains('/admin')));
    });

    test('admin console exists as a separate app', () {
      expect(File('apps/admin_web/pubspec.yaml').existsSync(), isTrue);
      expect(File('apps/admin_web/lib/main.dart').existsSync(), isTrue);
    });

    test('legacy public admin code is quarantined and not imported', () {
      expect(File('lib/features/admin/README.md').existsSync(), isTrue);

      final publicFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.contains(
              '${Platform.pathSeparator}features${Platform.pathSeparator}admin${Platform.pathSeparator}'));

      for (final file in publicFiles) {
        final source = file.readAsStringSync();
        expect(
          source,
          isNot(contains('features/admin/')),
          reason: '${file.path} must not import quarantined admin code.',
        );
      }
    });
  });
}
