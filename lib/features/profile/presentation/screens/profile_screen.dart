import 'dart:convert';
import 'dart:typed_data';

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
            tooltip: 'Edit profile',
            icon: Icon(Icons.edit_outlined, color: textColor),
            onPressed: () async {
              await context.push('/edit-profile');
              ref.invalidate(authStateProvider);
            },
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
                  _ProfileAvatar(
                    photoUrl: user?.photoUrl,
                    name: user?.name ?? '',
                    backgroundColor: bgColor,
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
            if (user?.isApprovedMerchant == true)
              _MenuItem(
                icon: Icons.storefront,
                title: 'Seller Center',
                textColor: textColor,
                secColor: secColor,
                onTap: () => context.push('/seller'),
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
              onTap: () => context.push('/orders'),
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
              onTap: () => _showHelpSupportMessage(context),
            ),
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

  void _showHelpSupportMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Help & support is not available in-app yet. Please contact the marketplace team from your order or chat details for now.',
        ),
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

class _ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final Color backgroundColor;

  const _ProfileAvatar({
    required this.photoUrl,
    required this.name,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final image = _imageProvider(photoUrl);
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.24),
          width: 4,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? Center(
              child: Text(
                name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: backgroundColor,
                ),
              ),
            )
          : Image(image: image, fit: BoxFit.cover),
    );
  }

  ImageProvider? _imageProvider(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('data:image')) {
      try {
        return MemoryImage(
            Uint8List.fromList(base64Decode(value.split(',').last)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(value);
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
