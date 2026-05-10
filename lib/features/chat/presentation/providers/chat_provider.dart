import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/models/chat_model.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

final userChatsProvider =
    StreamProvider.family<List<ChatModel>, String>((ref, userId) {
  final datasource = ref.watch(chatRemoteDataSourceProvider);
  return datasource.getChats(userId);
});

final chatByIdProvider =
    StreamProvider.family<ChatModel?, String>((ref, chatId) {
  final datasource = ref.watch(chatRemoteDataSourceProvider);
  return datasource.getChatStream(chatId);
});

class ChatNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String?> createChat({
    required String productId,
    required String productTitle,
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final ds = ref.read(chatRemoteDataSourceProvider);

      // Check if chat already exists
      final existing =
          await ds.getChatByParticipants(productId, buyerId, sellerId);
      if (existing != null) {
        state = const AsyncValue.data(null);
        return existing.id;
      }

      final chat = await ds.createChat(
        productId: productId,
        productTitle: productTitle,
        buyerId: buyerId,
        buyerName: buyerName,
        sellerId: sellerId,
        sellerName: sellerName,
      );

      state = const AsyncValue.data(null);
      return chat.id;
    } catch (e) {
      state = const AsyncValue.data(null);
      return e.toString();
    }
  }

  Future<String?> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    try {
      final ds = ref.read(chatRemoteDataSourceProvider);
      await ds.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        content: content,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final chatNotifierProvider =
    NotifierProvider<ChatNotifier, AsyncValue<void>>(() {
  return ChatNotifier();
});
