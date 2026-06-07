import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:olmeg_connect/core/config/environment.dart';

class AppErrorReporter {
  AppErrorReporter._();

  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _record(
        source: 'flutter',
        error: details.exceptionAsString(),
        stack: details.stack?.toString(),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _record(source: 'platform', error: '$error', stack: '$stack');
      return true;
    };
  }

  static Future<void> _record({
    required String source,
    required String error,
    String? stack,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('app_errors').add({
        'source': source,
        'error': error,
        'stack': stack,
        'platform': defaultTargetPlatform.name,
        'isWeb': kIsWeb,
        'environment': EnvironmentConfig.analyticsPrefix,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Error reporting must never create a second user-visible failure.
    }
  }
}
