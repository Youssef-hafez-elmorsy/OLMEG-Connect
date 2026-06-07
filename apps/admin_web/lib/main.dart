import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/admin_app.dart';
import 'core/monitoring/admin_error_reporter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await AdminErrorReporter.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AdminErrorReporter.install();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    runApp(const ProviderScope(child: AdminApp()));
  });
}
