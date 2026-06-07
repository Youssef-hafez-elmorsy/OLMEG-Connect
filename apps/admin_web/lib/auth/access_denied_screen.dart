import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/admin_tokens.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AdminGradients.shell),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AdminSpacing.lg),
          constraints: const BoxConstraints(maxWidth: 560),
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(AdminRadius.xl),
            border: Border.all(color: AdminColors.border),
            boxShadow: AdminShadows.floating,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: AdminColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AdminRadius.xl),
                  ),
                  child: const Icon(
                    Icons.lock_person_outlined,
                    size: 46,
                    color: AdminColors.danger,
                  ),
                ),
                const SizedBox(height: AdminSpacing.lg),
                Text(
                  'Access Denied',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AdminSpacing.sm),
                const Text(
                  'This console is only for approved Olmeg staff accounts. If you were recently promoted, sign out and sign in again to refresh Custom Claims.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AdminColors.muted, height: 1.5),
                ),
                const SizedBox(height: AdminSpacing.lg),
                Container(
                  decoration: BoxDecoration(
                    color: AdminColors.warningSoft,
                    borderRadius: BorderRadius.circular(AdminRadius.md),
                  ),
                  padding: const EdgeInsets.all(AdminSpacing.md),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.security_outlined, color: AdminColors.warning),
                      SizedBox(width: AdminSpacing.sm),
                      Expanded(
                        child: Text(
                          'Route guards are UX only. Firebase Custom Claims and Firestore Rules enforce the real boundary.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AdminSpacing.lg),
                FilledButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
