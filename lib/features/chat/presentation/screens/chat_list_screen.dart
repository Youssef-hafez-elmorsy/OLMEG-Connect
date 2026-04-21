import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final chatsAsync = ref.watch(userChatsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No messages yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Start a conversation by contacting a seller', style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUser = chat.buyerId == user.id ? chat.sellerName : chat.buyerName;
              return _ChatTile(chat: chat, currentUserId: user.id, otherUserName: otherUser);
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final String otherUserName;

  const _ChatTile({required this.chat, required this.currentUserId, required this.otherUserName});

  @override
  Widget build(BuildContext context) {
    final lastMessage = chat.messages.isNotEmpty ? chat.messages.last : null;
    final isBuyer = chat.buyerId == currentUserId;
    
    return ListTile(
      onTap: () => context.push('/chat/${chat.id}', extra: chat),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: Text(otherUserName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
      ),
      title: Text(chat.productTitle, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        lastMessage?['content'] ?? 'Start a conversation',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('MMM d').format(chat.updatedAt),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isBuyer ? Colors.blue.shade50 : Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(isBuyer ? 'Buyer' : 'Seller', style: TextStyle(fontSize: 10, color: isBuyer ? Colors.blue : Colors.purple)),
          ),
        ],
      ),
    );
  }
}