import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.isAdmin ?? false;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F7);
    final surfaceColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final secColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor =
        isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(l10n.profile, style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt, color: textColor),
            onPressed: () => context.push('/edit-profile'),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: () => ref.refresh(authStateProvider),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: textColor),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: dividerColor),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: bgColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user?.name ?? l10n.guest,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: secColor),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                          label: l10n.products,
                          value: '0',
                          textColor: textColor,
                          secColor: secColor),
                      _StatItem(
                          label: l10n.sold,
                          value: '0',
                          textColor: textColor,
                          secColor: secColor),
                      _StatItem(
                          label: l10n.rating,
                          value: '0.0',
                          textColor: textColor,
                          secColor: secColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _MenuItem(
              icon: Icons.shopping_bag,
              title: l10n.myProducts,
              textColor: textColor,
              secColor: secColor,
              onTap: () => context.push('/my-products'),
            ),
            _MenuItem(
              icon: Icons.favorite,
              title: l10n.favorites,
              textColor: textColor,
              secColor: secColor,
              onTap: () => context.push('/favorites'),
            ),
            _MenuItem(
              icon: Icons.history,
              title: l10n.orderHistory,
              textColor: textColor,
              secColor: secColor,
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.settings,
              title: l10n.settings,
              textColor: textColor,
              secColor: secColor,
              onTap: () => context.push('/settings'),
            ),
            _MenuItem(
              icon: Icons.help,
              title: l10n.helpSupport,
              textColor: textColor,
              secColor: secColor,
              onTap: () {},
            ),
            if (isAdmin) ...[
              _MenuItem(
                icon: Icons.admin_panel_settings,
                title: 'Admin Dashboard',
                textColor: textColor,
                secColor: secColor,
                onTap: () => context.push('/admin'),
              ),
              _MenuItem(
                icon: Icons.campaign,
                title: 'Admin Notifications',
                textColor: textColor,
                secColor: secColor,
                onTap: () => context.push('/admin/notify'),
              ),
              _MenuItem(
                icon: Icons.verified_user,
                title: 'Product Moderation',
                textColor: textColor,
                secColor: secColor,
                onTap: () => context.push('/admin/moderation'),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteAccountDialog(context, ref),
                icon: const Icon(Icons.delete_forever, color: AppColors.error),
                label: Text(l10n.deleteAccount,
                    style: const TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: Text(l10n.signOut,
                    style: const TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(l10n.deleteAccountQuestion,
            style: const TextStyle(color: Color(0xFFF8FAFC))),
        content: Text(
          l10n.deleteAccountWarning,
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount(context, ref);
            },
            child: Text(l10n.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .delete();
      await currentUser.delete();

      ref.read(authNotifierProvider.notifier).signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorDeletingAccount(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color secColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.textColor,
    required this.secColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
        Text(
          label,
          style: TextStyle(color: secColor, fontSize: 12),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textColor;
  final Color secColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.textColor,
    required this.secColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(Icons.chevron_right, color: secColor),
      onTap: onTap,
    );
  }
}
