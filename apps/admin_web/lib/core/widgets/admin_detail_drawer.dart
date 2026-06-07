import 'package:flutter/material.dart';

import 'admin_tokens.dart';

class AdminDetailDrawer extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> sections;
  final List<Widget> actions;

  const AdminDetailDrawer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 560,
      backgroundColor: AdminColors.page,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AdminGradients.command),
              padding: const EdgeInsets.all(AdminSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dataset_outlined, color: Colors.white),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminSpacing.md),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    subtitle,
                    style: const TextStyle(color: Color(0xFFE5E7EB)),
                  ),
                ],
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                child: Wrap(spacing: 8, runSpacing: 8, children: actions),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                children: [
                  for (final section in sections) ...[
                    section,
                    const SizedBox(height: AdminSpacing.md),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AdminDetailSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AdminColors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: AdminSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AdminSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}
