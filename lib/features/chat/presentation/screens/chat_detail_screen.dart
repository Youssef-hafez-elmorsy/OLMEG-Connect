import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../../../../core/theme/app_theme.dart';

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
    
    final error = await ref.read(chatNotifierProvider.notifier).sendMessage(
      chatId: widget.chat.id,
      senderId: user.id,
      senderName: user.name,
      content: _messageCtrl.text.trim(),
    );

    setState(() => _isLoading = false);
    
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } else {
      _messageCtrl.clear();
      // Scroll to bottom
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
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final isBuyer = widget.chat.buyerId == user.id;
    final otherUser = isBuyer ? widget.chat.sellerName : widget.chat.buyerName;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherUser, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(widget.chat.productTitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Product info bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.chat.productTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: widget.chat.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('No messages yet', style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text('Say hello to $otherUser!', style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.chat.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.chat.messages[index];
                      final isMe = message['senderId'] == user.id;
                      return _MessageBubble(
                        content: message['content'],
                        senderName: message['senderName'],
                        isMe: isMe,
                        time: DateTime.tryParse(message['createdAt'] ?? '') ?? DateTime.now(),
                      );
                    },
                  ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final String senderName;
  final bool isMe;
  final DateTime time;

  const _MessageBubble({
    required this.content,
    required this.senderName,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(senderName, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            Text(content, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
            Text(
              DateFormat('h:mm a').format(time),
              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}