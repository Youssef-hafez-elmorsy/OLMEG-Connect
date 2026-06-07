import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/screen_performance_probe.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_model.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppColors.getBackground(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            AppLocalizations.of(context).t('pleaseSignIn'),
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    final chatsAsync = ref.watch(userChatsProvider(user.id));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(l10n.t('messages')),
        actions: [
          IconButton(
            tooltip: l10n.t('refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userChatsProvider(user.id)),
          ),
        ],
      ),
      body: ScreenPerformanceProbe(
        screenName: 'chat_list',
        child: chatsAsync.when(
          loading: () => const _ChatListLoadingState(),
          error: (e, _) => _ChatListErrorState(
            error: e.toString(),
            onRetry: () => ref.invalidate(userChatsProvider(user.id)),
          ),
          data: (chats) {
            final filtered = chats.where((chat) {
              final otherUser =
                  chat.buyerId == user.id ? chat.sellerName : chat.buyerName;
              final text = '${chat.productTitle} $otherUser '
                      '${chat.messages.isNotEmpty ? chat.messages.last['content'] : ''}'
                  .toLowerCase();
              return text.contains(_query.toLowerCase().trim());
            }).toList();

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(userChatsProvider(user.id)),
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: _ChatInboxHeader(
                      totalChats: chats.length,
                      buyingChats:
                          chats.where((chat) => chat.buyerId == user.id).length,
                      sellingChats: chats
                          .where((chat) => chat.sellerId == user.id)
                          .length,
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  if (chats.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ChatListEmptyState(),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ChatSearchEmptyState(query: _query),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final chat = filtered[index];
                          final otherUser = chat.buyerId == user.id
                              ? chat.sellerName
                              : chat.buyerName;
                          return _ChatTile(
                            chat: chat,
                            currentUserId: user.id,
                            otherUserName: otherUser,
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatInboxHeader extends StatelessWidget {
  final int totalChats;
  final int buyingChats;
  final int sellingChats;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _ChatInboxHeader({
    required this.totalChats,
    required this.buyingChats,
    required this.sellingChats,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);
    final inputFillColor = AppColors.getSurface(isDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.forum_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('marketplaceInbox'),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.chatStats(totalChats, buyingChats, sellingChats),
                        style: TextStyle(color: secondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: l10n.t('searchMessages'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
              filled: true,
              fillColor: inputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final String currentUserId;
  final String otherUserName;

  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMessage = chat.messages.isNotEmpty ? chat.messages.last : null;
    final isBuyer = chat.buyerId == currentUserId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.getSurface(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);
    final l10n = AppLocalizations.of(context);

    final lastContent = lastMessage?['content']?.toString() ?? '';
    final hasRecentMessage = lastContent.trim().isNotEmpty;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => context.push('/chat/${chat.id}', extra: chat),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary,
                child: Text(
                  otherUserName.isNotEmpty
                      ? otherUserName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM d').format(chat.updatedAt),
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      chat.productTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasRecentMessage
                          ? lastContent
                          : l10n.t('startConversation'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: secondaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      isBuyer ? l10n.t('buying') : l10n.t('selling'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.t('deleteConversation'),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: secondaryColor,
                    ),
                    onPressed: () => _confirmHide(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmHide(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(AppLocalizations.of(context).t('deleteConversationQuestion')),
        content: Text(AppLocalizations.of(context).t('deleteConversationHelp')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await ref.read(chatNotifierProvider.notifier).hideChat(
          chatId: chat.id,
          userId: currentUserId,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error == null
            ? AppLocalizations.of(context).t('conversationDeleted')
            : '${AppLocalizations.of(context).t('couldNotDeleteConversation')}: $error'),
      ),
    );
  }
}

class _ChatListLoadingState extends StatelessWidget {
  const _ChatListLoadingState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = AppColors.getSurface(isDark);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          height: index == 0 ? 132 : 84,
          decoration: BoxDecoration(
            color: placeholderColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        );
      },
    );
  }
}

class _ChatListErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ChatListErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context).t('couldNotLoadMessages'),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryColor),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListEmptyState extends StatelessWidget {
  const _ChatListEmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: secondaryColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context).t('noMessagesYet'),
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.of(context).t('contactSellerToStart'),
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatSearchEmptyState extends StatelessWidget {
  final String query;

  const _ChatSearchEmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 56, color: secondaryColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context).noChatsMatch(query),
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
