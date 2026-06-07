import 'dart:async';

import 'package:flutter/foundation.dart';

class AdminErrorReporter {
  const AdminErrorReporter._();

  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[AdminError] ${details.exceptionAsString()}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[AdminPlatformError] $error\n$stack');
      return true;
    };
  }

  static Future<void> runGuarded(FutureOr<void> Function() body) {
    final guarded = runZonedGuarded<Future<void>>(
      () async => await body(),
      (error, stack) {
        debugPrint('[AdminZoneError] $error\n$stack');
      },
    );
    return guarded ?? Future<void>.value();
  }
}
