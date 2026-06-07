import 'package:flutter/material.dart';

class AdminColors {
  static const ink = Color(0xFF10131A);
  static const inkSoft = Color(0xFF1A2232);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
  static const page = Color(0xFFF4F1EA);
  static const pageAlt = Color(0xFFECE7DC);
  static const card = Colors.white;
  static const cardWarm = Color(0xFFFFFCF5);
  static const border = Color(0xFFE6DDCE);
  static const primary = Color(0xFF0E7C72);
  static const primarySoft = Color(0xFFE4F6F2);
  static const accent = Color(0xFFF97316);
  static const accentSoft = Color(0xFFFFE9D6);
  static const info = Color(0xFF265DAD);
  static const infoSoft = Color(0xFFEAF2FF);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFFF2CE);
  static const danger = Color(0xFFC2410C);
  static const dangerSoft = Color(0xFFFFE7DD);
  static const success = Color(0xFF16835F);
  static const successSoft = Color(0xFFE4F7EC);
  static const sidebar = Color(0xFF111827);
  static const sidebarHover = Color(0xFF1F2937);
}

class AdminSpacing {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 44.0;
}

class AdminRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AdminBreakpoints {
  static const compact = 860.0;
  static const wide = 1180.0;
  static const maxContent = 1560.0;
}

class AdminShadows {
  static const card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 30,
      offset: Offset(0, 18),
    ),
  ];

  static const floating = [
    BoxShadow(
      color: Color(0x24000000),
      blurRadius: 44,
      offset: Offset(0, 24),
    ),
  ];
}

class AdminGradients {
  static const shell = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF9F2E5),
      Color(0xFFE9F5F1),
      Color(0xFFF7E7D6),
    ],
  );

  static const command = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF132E3A),
      Color(0xFF0E7C72),
      Color(0xFFF97316),
    ],
  );
}

ButtonStyle adminPrimaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AdminColors.ink,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AdminRadius.md),
    ),
  );
}
