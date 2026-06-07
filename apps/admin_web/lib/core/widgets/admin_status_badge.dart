import 'package:flutter/material.dart';

import 'admin_tokens.dart';

class AdminStatusBadge extends StatelessWidget {
  final String label;
  final AdminStatusTone tone;
  final IconData? icon;

  const AdminStatusBadge({
    super.key,
    required this.label,
    this.tone = AdminStatusTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colors(tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.$2.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: colors.$2),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: colors.$2,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AdminStatusTone { neutral, success, warning, danger, info }

(Color, Color) _colors(AdminStatusTone tone) {
  return switch (tone) {
    AdminStatusTone.success => (AdminColors.successSoft, AdminColors.success),
    AdminStatusTone.warning => (AdminColors.warningSoft, AdminColors.warning),
    AdminStatusTone.danger => (AdminColors.dangerSoft, AdminColors.danger),
    AdminStatusTone.info => (AdminColors.infoSoft, AdminColors.info),
    AdminStatusTone.neutral => (const Color(0xFFF1F5F9), AdminColors.muted),
  };
}

AdminStatusTone adminToneForStatus(String? rawStatus) {
  final status = (rawStatus ?? '').toLowerCase();
  if (status.contains('approved') ||
      status.contains('active') ||
      status.contains('sent') ||
      status.contains('resolved')) {
    return AdminStatusTone.success;
  }
  if (status.contains('pending') ||
      status.contains('submitted') ||
      status.contains('open') ||
      status.contains('escalated')) {
    return AdminStatusTone.warning;
  }
  if (status.contains('rejected') ||
      status.contains('banned') ||
      status.contains('blocked') ||
      status.contains('deleted') ||
      status.contains('failed') ||
      status.contains('suspended')) {
    return AdminStatusTone.danger;
  }
  return AdminStatusTone.neutral;
}
