import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SettingsTile(
            icon: Icons.light_mode,
            title: l10n.lightMode,
            trailing: Switch(
              value: !settings.isDarkMode,
              onChanged: (_) =>
                  ref.read(settingsNotifierProvider.notifier).toggleDarkMode(),
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return AppColors.textSecondary;
              }),
            ),
          ),
          _SettingsTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: settings.language == AppLanguage.arabic
                ? l10n.arabic
                : l10n.english,
            onTap: () => _showLanguageDialog(context, ref),
          ),
          _SettingsTile(
            icon: Icons.notifications,
            title: l10n.notifications,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip,
            title: l10n.privacyPolicy,
            onTap: () => context.push('/privacy-policy'),
          ),
          _SettingsTile(
            icon: Icons.description,
            title: l10n.termsOfService,
            onTap: () => context.push('/terms'),
          ),
          _SettingsTile(
            icon: Icons.info,
            title: l10n.about,
            subtitle: l10n.version,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLang = ref.read(settingsNotifierProvider).language;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.selectLanguage,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              label: l10n.english,
              isSelected: currentLang == AppLanguage.english,
              onTap: () {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setLanguage(AppLanguage.english);
                Navigator.pop(dialogContext);
              },
            ),
            _LanguageOption(
              label: l10n.arabic,
              isSelected: currentLang == AppLanguage.arabic,
              onTap: () {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setLanguage(AppLanguage.arabic);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: AppColors.textSecondary))
          : null,
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap ?? () {},
    );
  }
}
