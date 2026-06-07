import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/chat_model.dart';

abstract class ChatRemoteDataSource {
  Stream<List<ChatModel>> getChats(String userId);
  Stream<ChatModel?> getChatStream(String chatId);
  Future<ChatModel?> getChatById(String chatId);
  Future<ChatModel?> getChatByParticipants(
      String productId, String buyerId, String sellerId);
  Future<ChatModel> createChat(
      {required String productId,
      required String productTitle,
      required String buyerId,
      required String buyerName,
      required String sellerId,
      required String sellerName});
  Future<void> sendMessage(
      {required String chatId,
      required String senderId,
      required String senderName,
      required String content});
  Future<void> hideChatForUser(String chatId, String userId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  ChatRemoteDataSourceImpl(
      {required FirebaseFirestore firestore, required FirebaseStorage storage})
      : _firestore = firestore;

  CollectionReference get _col =>
      _firestore.collection(AppConstants.chatsCollection);

  @override
  Stream<List<ChatModel>> getChats(String userId) {
    return _col
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .limit(80)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChatModel.fromFirestore(d))
            .where((chat) => !chat.hiddenFor.contains(userId))
            .toList());
  }

  @override
  Stream<ChatModel?> getChatStream(String chatId) {
    return _col.doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatModel.fromFirestore(doc);
    });
  }

  @override
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _col.doc(chatId).get();
      if (!doc.exists) return null;
      return ChatModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ChatModel?> getChatByParticipants(
      String productId, String buyerId, String sellerId) async {
    try {
      final snapshot = await _col
          .where('productId', isEqualTo: productId)
          .where('buyerId', isEqualTo: buyerId)
          .where('sellerId', isEqualTo: sellerId)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return ChatModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ChatModel> createChat({
    required String productId,
    required String productTitle,
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
  }) async {
    final chatId = _uuid.v4();
    final now = DateTime.now();

    final model = ChatModel(
      id: chatId,
      productId: productId,
      productTitle: productTitle,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: sellerId,
      sellerName: sellerName,
      messages: [],
      participants: [buyerId, sellerId],
      hiddenFor: const [],
      createdAt: now,
      updatedAt: now,
    );

    await _col.doc(chatId).set(model.toFirestore());
    return model;
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final message = {
      'id': _uuid.v4(),
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _col.doc(chatId).update({
      'messages': FieldValue.arrayUnion([message]),
      'updatedAt': DateTime.now(),
      'hiddenFor': FieldValue.arrayRemove([senderId]),
    });
  }

  @override
  Future<void> hideChatForUser(String chatId, String userId) async {
    await _col.doc(chatId).set({
      'hiddenFor': FieldValue.arrayUnion([userId]),
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));
  }
}
