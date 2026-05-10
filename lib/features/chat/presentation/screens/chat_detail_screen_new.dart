import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/theme/app_theme_helper.dart';
import 'package:olmeg_connect/features/chat/data/models/chat_model.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isOwn;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isOwn,
  });
}

class ChatDetailScreen extends ConsumerStatefulWidget {
  final ChatModel chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  late TextEditingController _messageController;
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      senderId: 'user1',
      senderName: 'John Doe',
      message: 'Hi, is this product still available?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isOwn: false,
    ),
    ChatMessage(
      id: '2',
      senderId: 'user2',
      senderName: 'You',
      message: 'Yes, it is! Would you like to know more details?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      isOwn: true,
    ),
    ChatMessage(
      id: '3',
      senderId: 'user1',
      senderName: 'John Doe',
      message: 'What\'s the condition? Is it new or used?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      isOwn: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          senderId: 'user2',
          senderName: 'You',
          message: _messageController.text,
          timestamp: DateTime.now(),
          isOwn: true,
        ),
      );
    });

    _messageController.clear();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeHelper.background(context),
      appBar: AppBar(
        backgroundColor: AppThemeHelper.background(context),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chat.productTitle,
              style: TextStyle(
                fontSize: 14,
                color: AppThemeHelper.textSecondary(context),
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              widget.chat.sellerName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppThemeHelper.textPrimary(context),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppThemeHelper.textPrimary(context)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: message.isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!message.isOwn)
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              message.senderName[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: message.isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: message.isOwn
                                    ? AppColors.primary
                                    : AppThemeHelper.surface(context),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: message.isOwn
                                    ? null
                                    : Border.all(
                                        color: AppThemeHelper.divider(context),
                                        width: 1,
                                      ),
                              ),
                              child: Text(
                                message.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: message.isOwn
                                      ? AppThemeHelper.background(context)
                                      : AppThemeHelper.textPrimary(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppThemeHelper.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (message.isOwn) const SizedBox(width: AppSpacing.sm),
                      if (message.isOwn)
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'Y',
                              style: TextStyle(
                                color: AppColors.background,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppThemeHelper.surface(context),
              border: Border(
                top: BorderSide(
                  color: AppThemeHelper.divider(context),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: AppThemeHelper.textSecondary(context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          borderSide: BorderSide(
                            color: AppThemeHelper.divider(context),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          borderSide: BorderSide(
                            color: AppThemeHelper.divider(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.attach_file,
                            color: AppThemeHelper.textSecondary(context),
                          ),
                          onPressed: () {},
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: AppColors.background,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
