import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/features/cart/presentation/screens/checkout_review_screen.dart';
import 'package:olmeg_connect/features/profile/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QA stabilization guards', () {
    test('router does not force-cast navigation extras for direct links', () {
      final routerSource = File('lib/core/router/app_router.dart').readAsStringSync();

      expect(routerSource, isNot(contains('state.extra as ProductEntity')));
      expect(routerSource, isNot(contains('state.extra as ChatModel')));
    });

    test('production lib code does not contain empty tap handlers', () {
      final emptyHandlerPattern = RegExp(
        r'on(?:Pressed|Tap|LongPress):\s*\(\)\s*\{\s*\}',
      );
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.dart') || file.path.endsWith('.hook'))
          .where((file) => emptyHandlerPattern.hasMatch(file.readAsStringSync()))
          .map((file) => file.path)
          .toList();

      expect(offenders, isEmpty);
    });
  });

  group('QA stabilization smoke widgets', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('checkout explains why order creation is disabled',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CheckoutReviewScreen(),
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Create order and continue to payment'),
        300,
      );

      expect(find.text('Create order and continue to payment'), findsOneWidget);
      expect(
        find.text('Add at least one available item to continue.'),
        findsOneWidget,
      );
    });

    testWidgets('settings notification tile navigates and about opens',
        (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const Scaffold(
              body: Text('Notifications route opened'),
            ),
          ),
          GoRoute(
            path: '/privacy-policy',
            builder: (_, __) => const Scaffold(body: Text('Privacy')),
          ),
          GoRoute(
            path: '/terms',
            builder: (_, __) => const Scaffold(body: Text('Terms')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Notifications route opened'), findsOneWidget);

      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutDialog), findsOneWidget);
    });

    testWidgets('settings can render in Arabic RTL locale', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(SettingsScreen))),
        TextDirection.rtl,
      );
    });
  });
}
