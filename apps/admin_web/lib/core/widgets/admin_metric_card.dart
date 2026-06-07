import 'package:flutter/material.dart';

import 'admin_tokens.dart';

class AdminMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  final String trend;

  const AdminMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    this.color = AdminColors.primary,
    this.trailing,
    this.trend = 'Live',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -42,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AdminRadius.lg),
                        border:
                            Border.all(color: color.withValues(alpha: 0.14)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(icon, color: color, size: 24),
                      ),
                    ),
                    const Spacer(),
                    trailing ??
                        _TrendPill(
                          label: trend,
                          color: color,
                        ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AdminColors.ink,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: AdminSpacing.xs),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  final String label;
  final Color color;

  const _TrendPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
