import 'package:flutter/material.dart';

import 'admin_tokens.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Widget> actions;
  final Widget child;
  final Widget? bottom;
  final String eyebrow;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
    this.actions = const [],
    this.bottom,
    this.eyebrow = 'Operations',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < AdminBreakpoints.compact;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AdminBreakpoints.maxContent,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? AdminSpacing.sm : AdminSpacing.md,
                    AdminSpacing.sm,
                    compact ? AdminSpacing.sm : AdminSpacing.md,
                    AdminSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageNavigationBar(
                        title: title,
                        description: description,
                        icon: icon,
                        actions: actions,
                        compact: compact,
                        eyebrow: eyebrow,
                        bottom: bottom,
                      ),
                      const SizedBox(height: AdminSpacing.sm),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageNavigationBar extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Widget> actions;
  final bool compact;
  final String eyebrow;
  final Widget? bottom;

  const _PageNavigationBar({
    required this.title,
    required this.description,
    required this.icon,
    required this.actions,
    required this.compact,
    required this.eyebrow,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AdminSpacing.sm,
              AdminSpacing.sm,
              AdminSpacing.sm,
              bottom == null ? AdminSpacing.sm : AdminSpacing.xs,
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderText(
                        title: title,
                        description: description,
                        icon: icon,
                        eyebrow: eyebrow,
                      ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: AdminSpacing.sm),
                        Wrap(spacing: 10, runSpacing: 10, children: actions),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _HeaderText(
                          title: title,
                          description: description,
                          icon: icon,
                          eyebrow: eyebrow,
                        ),
                      ),
                      if (actions.isNotEmpty)
                        Wrap(spacing: 10, runSpacing: 10, children: actions),
                    ],
                  ),
          ),
          if (bottom != null) ...[
            const Divider(height: 1, color: AdminColors.border),
            Padding(
              padding: const EdgeInsets.all(AdminSpacing.xs),
              child: bottom!,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String eyebrow;

  const _HeaderText({
    required this.title,
    required this.description,
    required this.icon,
    required this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AdminGradients.command,
            borderRadius: BorderRadius.circular(AdminRadius.sm),
            boxShadow: [
              BoxShadow(
                color: AdminColors.primary.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: AdminSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: AdminColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AdminColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AdminColors.muted,
                  fontSize: 11,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
