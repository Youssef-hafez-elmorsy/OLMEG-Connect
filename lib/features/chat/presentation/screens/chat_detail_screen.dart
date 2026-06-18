import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/chat/data/models/chat_model.dart';
import 'package:olmeg_connect/features/chat/presentation/providers/chat_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final ChatModel chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageCtrl.text.trim().isEmpty) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    final content = _messageCtrl.text.trim();

    final error = await ref.read(chatNotifierProvider.notifier).sendMessage(
          chatId: widget.chat.id,
          senderId: user.id,
          senderName: user.name,
          content: content,
        );

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    } else {
      _messageCtrl.clear();
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppColors.getBackground(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    final l10n = AppLocalizations.of(context);
    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child:
              Text(l10n.t('pleaseSignIn'), style: TextStyle(color: textColor)),
        ),
      );
    }

    final chatAsync = ref.watch(chatByIdProvider(widget.chat.id));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: chatAsync.when(
        loading: () => const _ChatDetailLoadingState(),
        error: (error, _) => _ChatDetailErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(chatByIdProvider(widget.chat.id)),
        ),
        data: (latestChat) {
          final chat = latestChat ?? widget.chat;
          final liveIsBuyer = chat.buyerId == user.id;
          final otherUser = liveIsBuyer ? chat.sellerName : chat.buyerName;
          final messages = chat.orderedMessages;
          final isBlocked = chat.blockedBy.contains(user.id);

          return Column(
            children: [
              _ConversationHeader(
                otherUser: otherUser,
                productTitle: chat.productTitle,
                roleLabel: liveIsBuyer ? l10n.t('buying') : l10n.t('selling'),
                onBack: () => context.pop(),
                onOptions: () => _showConversationOptions(chat, user.id),
              ),
              _ProductContextBar(
                productTitle: chat.productTitle,
                safetyStatus: chat.safetyStatus,
              ),
              Expanded(
                child: messages.isEmpty
                    ? _EmptyConversationState(otherUser: otherUser)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe =
                              ChatMessageFields.senderId(message) == user.id;
                          final time = ChatMessageFields.createdAt(message);
                          final previous =
                              index > 0 ? messages[index - 1] : null;
                          final previousTime = previous == null
                              ? null
                              : ChatMessageFields.createdAt(previous);
                          final showDate = previousTime == null ||
                              previousTime.year != time.year ||
                              previousTime.month != time.month ||
                              previousTime.day != time.day;
                          return _MessageBubble(
                            content: ChatMessageFields.content(message),
                            senderName: ChatMessageFields.senderName(message),
                            isMe: isMe,
                            time: time,
                            status: ChatMessageFields.status(message),
                            showDate: showDate,
                            onReport: () => _showReportDialog(
                              chatId: chat.id,
                              reporterId: user.id,
                              messageId: ChatMessageFields.id(message),
                            ),
                          );
                        },
                      ),
              ),
              if (isBlocked)
                _ConversationBlockedNotice(
                  onUnblock: () => _setBlocked(chat.id, user.id, false),
                ),
              _MessageInputBar(
                controller: _messageCtrl,
                isLoading: _isLoading || isBlocked,
                onAttach: _showAttachmentUnavailable,
                onSend: isBlocked ? () {} : _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showConversationOptions(ChatModel chat, String userId) async {
    final isMuted = chat.mutedFor.contains(userId);
    final isBlocked = chat.blockedBy.contains(userId);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isMuted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: Text(AppLocalizations.of(context)
                  .t(isMuted ? 'unmuteConversation' : 'muteConversation')),
              subtitle:
                  Text(AppLocalizations.of(context).t('muteConversationHelp')),
              onTap: () => Navigator.pop(context, 'mute'),
            ),
            ListTile(
              leading: Icon(
                isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
              ),
              title: Text(AppLocalizations.of(context)
                  .t(isBlocked ? 'unblockConversation' : 'blockConversation')),
              subtitle:
                  Text(AppLocalizations.of(context).t('blockConversationHelp')),
              onTap: () => Navigator.pop(context, 'block'),
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: Text(AppLocalizations.of(context).t('reportConversation')),
              subtitle: Text(
                  AppLocalizations.of(context).t('reportConversationHelp')),
              onTap: () => Navigator.pop(context, 'report'),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: Text(AppLocalizations.of(context).t('hideConversation')),
              subtitle: Text(
                  AppLocalizations.of(context).t('otherKeepsConversation')),
              onTap: () => Navigator.pop(context, 'hide'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(AppLocalizations.of(context).cancel),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;
    if (action == 'report') {
      await _showReportDialog(chatId: chat.id, reporterId: userId);
      return;
    }
    if (action == 'mute') {
      await _setMuted(chat.id, userId, !isMuted);
      return;
    }
    if (action == 'block') {
      await _setBlocked(chat.id, userId, !isBlocked);
      return;
    }
    if (action != 'hide') return;
    final error = await ref.read(chatNotifierProvider.notifier).hideChat(
          chatId: chat.id,
          userId: userId,
        );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('conversationHidden')),
      ),
    );
    context.go('/chats');
  }

  Future<void> _setMuted(String chatId, String userId, bool muted) async {
    final error = await ref.read(chatNotifierProvider.notifier).muteChat(
          chatId: chatId,
          userId: userId,
          muted: muted,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ??
            AppLocalizations.of(context)
                .t(muted ? 'conversationMuted' : 'conversationUnmuted')),
      ),
    );
  }

  Future<void> _setBlocked(String chatId, String userId, bool blocked) async {
    final error = await ref.read(chatNotifierProvider.notifier).blockChat(
          chatId: chatId,
          userId: userId,
          blocked: blocked,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ??
            AppLocalizations.of(context)
                .t(blocked ? 'conversationBlocked' : 'conversationUnblocked')),
      ),
    );
  }

  Future<void> _showReportDialog({
    required String chatId,
    required String reporterId,
    String? messageId,
  }) async {
    final reasonController = TextEditingController(text: 'unsafe_content');
    final descriptionController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('reportConversation')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).t('reportReason'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText:
                    AppLocalizations.of(context).t('reportDescriptionOptional'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.report_outlined),
            label: Text(AppLocalizations.of(context).t('submitReport')),
          ),
        ],
      ),
    );
    if (submitted != true) return;
    final error = await ref.read(chatNotifierProvider.notifier).reportChat(
          chatId: chatId,
          messageId: messageId,
          reporterId: reporterId,
          reason: reasonController.text,
          description: descriptionController.text,
        );
    reasonController.dispose();
    descriptionController.dispose();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            error ?? AppLocalizations.of(context).t('conversationReported')),
      ),
    );
  }

  void _showAttachmentUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('attachmentsUnavailable')),
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  final String otherUser;
  final String productTitle;
  final String roleLabel;
  final VoidCallback onBack;
  final VoidCallback onOptions;

  const _ConversationHeader({
    required this.otherUser,
    required this.productTitle,
    required this.roleLabel,
    required this.onBack,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.getSurface(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);
    final dividerColor = AppColors.getDivider(isDark);
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            bottom: BorderSide(color: dividerColor.withValues(alpha: 0.8)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: onBack,
            ),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Text(
                otherUser.isNotEmpty ? otherUser[0].toUpperCase() : 'U',
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
                          otherUser,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).t('conversationOptions'),
              icon: Icon(Icons.more_vert, color: textColor),
              onPressed: onOptions,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductContextBar extends StatelessWidget {
  final String productTitle;
  final String safetyStatus;

  const _ProductContextBar({
    required this.productTitle,
    required this.safetyStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.getTextPrimary(isDark);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              productTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (safetyStatus != 'normal')
            const Icon(Icons.verified_user_outlined, color: AppColors.warning)
          else
            const Icon(Icons.lock_outline, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  final String otherUser;

  const _EmptyConversationState({required this.otherUser});

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
              size: 54,
              color: secondaryColor,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.of(context).t('noMessagesYet'),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppLocalizations.of(context).emptyConversationMessage(otherUser),
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.isLoading,
    required this.onAttach,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.getSurface(isDark);
    final cardColor = AppColors.getCard(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: AppLocalizations.of(context).t('addAttachment'),
              onPressed: onAttach,
              icon: Icon(Icons.add_circle_outline, color: secondaryColor),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: textColor),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => isLoading ? null : onSend(),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).t('typeMessage'),
                  hintStyle: TextStyle(color: secondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              tooltip: AppLocalizations.of(context).t('send'),
              onPressed: isLoading ? null : onSend,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.background,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatDetailLoadingState extends StatelessWidget {
  const _ChatDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = AppColors.getSurface(isDark);
    return Column(
      children: [
        Container(height: 92, color: placeholderColor),
        const LinearProgressIndicator(color: AppColors.primary),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Align(
                alignment:
                    index.isEven ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 190,
                  height: 48,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChatDetailErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ChatDetailErrorState({
    required this.error,
    required this.onRetry,
  });

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
              AppLocalizations.of(context).t('couldNotLoadConversation'),
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

class _MessageBubble extends StatelessWidget {
  final String content;
  final String senderName;
  final bool isMe;
  final DateTime time;
  final String status;
  final bool showDate;
  final VoidCallback onReport;

  const _MessageBubble({
    required this.content,
    required this.senderName,
    required this.isMe,
    required this.time,
    required this.status,
    required this.showDate,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.getSurface(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);
    final dividerColor = AppColors.getDivider(isDark);
    return Column(
      children: [
        if (showDate)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              DateFormat('EEE, MMM d').format(time),
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
              ),
            ),
          ),
        GestureDetector(
          onLongPress: onReport,
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 310),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
                    bottomRight: isMe ? const Radius.circular(4) : null,
                    bottomLeft: !isMe ? const Radius.circular(4) : null,
                  ),
                  border: isMe ? null : Border.all(color: dividerColor),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 10,
                          color: secondaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      content,
                      style: TextStyle(
                        height: 1.35,
                        color: isMe ? AppColors.background : textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('h:mm a').format(time),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? AppColors.background.withValues(alpha: 0.7)
                                : secondaryColor,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            status == 'failed'
                                ? Icons.error_outline
                                : Icons.done_all,
                            size: 12,
                            color: AppColors.background.withValues(alpha: 0.75),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConversationBlockedNotice extends StatelessWidget {
  final VoidCallback onUnblock;

  const _ConversationBlockedNotice({required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_outlined, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(AppLocalizations.of(context).t('blockedNotice')),
          ),
          TextButton(
            onPressed: onUnblock,
            child: Text(AppLocalizations.of(context).t('unblockConversation')),
          ),
        ],
      ),
    );
  }
}
