import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firebase App Check guard', () {
    test('public app activates App Check providers', () {
      final mainSource = File('lib/main.dart').readAsStringSync();
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, contains('firebase_app_check'));
      expect(mainSource, contains('FirebaseAppCheck.instance.activate'));
      expect(mainSource, contains('AndroidPlayIntegrityProvider'));
      expect(mainSource, contains('setTokenAutoRefreshEnabled(true)'));
    });
  });
}
