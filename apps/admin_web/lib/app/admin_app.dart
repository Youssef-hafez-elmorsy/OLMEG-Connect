import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_router.dart';
import '../core/widgets/admin_tokens.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AdminColors.primary,
      brightness: Brightness.light,
    );
    return MaterialApp.router(
      title: 'Olmeg Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: baseScheme.copyWith(
          surface: AdminColors.card,
          primary: AdminColors.primary,
          secondary: AdminColors.accent,
          error: AdminColors.danger,
        ),
        scaffoldBackgroundColor: AdminColors.page,
        textTheme: GoogleFonts.manropeTextTheme().copyWith(
          headlineLarge: GoogleFonts.spaceGrotesk(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
            color: AdminColors.ink,
          ),
          headlineMedium: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            color: AdminColors.ink,
          ),
          headlineSmall: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AdminColors.ink,
          ),
        ),
        cardTheme: CardThemeData(
          color: AdminColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminRadius.lg),
            side: const BorderSide(color: AdminColors.border),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: adminPrimaryButtonStyle(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AdminColors.cardWarm,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminRadius.md),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminRadius.md),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminRadius.md),
            borderSide: const BorderSide(color: AdminColors.primary, width: 2),
          ),
        ),
        useMaterial3: true,
      ),
      routerConfig: adminRouter,
    );
  }
}
