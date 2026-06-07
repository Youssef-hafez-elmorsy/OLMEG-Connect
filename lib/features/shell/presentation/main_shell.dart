import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/home/presentation/screens/home_screen.dart';
import 'package:olmeg_connect/features/products/presentation/screens/add_product_screen.dart';
import 'package:olmeg_connect/features/profile/presentation/screens/profile_screen.dart';
import 'package:olmeg_connect/features/posts/screens/posts_main_shell.dart';
import 'package:olmeg_connect/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:olmeg_connect/features/notifications/presentation/providers/notification_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PostsMainShell(),
    AddProductScreen(),
    ChatListScreen(),
    NotificationsScreen(),
    UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F7);
    final surfaceColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final dividerColor =
        isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);

    final user = ref.watch(authStateProvider).value;
    final unreadCountAsync = user != null
        ? ref.watch(unreadNotificationCountProvider(user.id))
        : const AsyncValue.data(0);

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(color: dividerColor, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: l10n.home,
                  isSelected: _currentIndex == 0,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.article_outlined,
                  selectedIcon: Icons.article,
                  label: l10n.feed,
                  isSelected: _currentIndex == 1,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                Semantics(
                  button: true,
                  selected: _currentIndex == 2,
                  label: 'Create product or post',
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 2),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add,
                        color: bgColor,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline,
                  selectedIcon: Icons.chat_bubble,
                  label: l10n.chat,
                  isSelected: _currentIndex == 3,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                Stack(
                  children: [
                    _NavItem(
                      icon: Icons.notifications_outlined,
                      selectedIcon: Icons.notifications,
                      label: l10n.notify,
                      isSelected: _currentIndex == 4,
                      isDark: isDark,
                      onTap: () => setState(() => _currentIndex = 4),
                    ),
                    unreadCountAsync.when(
                      data: (count) {
                        if (count > 0) {
                          return Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 18, minHeight: 18),
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: l10n.profile,
                  isSelected: _currentIndex == 5,
                  isDark: isDark,
                  onTap: () => setState(() => _currentIndex = 5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primary : textColor,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : textColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
