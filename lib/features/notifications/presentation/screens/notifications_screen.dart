import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/notifications/presentation/providers/notification_provider.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('notificationsTitle')),
        elevation: 0,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(l10n.t('signInNotifications')),
            );
          }

          final notificationsAsync =
              ref.watch(userNotificationsProvider(user.id));

          return notificationsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.errorWithMessage(error)),
                ],
              ),
            ),
            data: (notifications) {
              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.t('noNotificationsYet'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getNotificationIcon(notification.type),
                        color: AppColors.primary,
                      ),
                      title: Text(notification.title),
                      subtitle: Text(notification.message),
                      trailing: notification.read
                          ? null
                          : Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () {
                        if (!notification.read) {
                          ref.read(
                              markNotificationAsReadProvider(notification.id));
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text(l10n.errorWithMessage(error)),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'post_liked':
        return Icons.favorite;
      case 'comment_added':
        return Icons.comment;
      case 'product_sold':
        return Icons.shopping_bag;
      case 'message_received':
        return Icons.message;
      case 'rating_received':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }
}
