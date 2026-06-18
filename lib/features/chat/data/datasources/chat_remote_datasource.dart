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
  Future<void> muteChatForUser(String chatId, String userId, bool muted);
  Future<void> blockChatForUser(String chatId, String userId, bool blocked);
  Future<void> reportChat({
    required String chatId,
    String? messageId,
    required String reporterId,
    required String reason,
    String description,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  ChatRemoteDataSourceImpl(
      {required FirebaseFirestore firestore, required FirebaseStorage storage})
      : _firestore = firestore;

  CollectionReference get _col =>
      _firestore.collection(AppConstants.chatsCollection);

  static const int maxMessageLength = 1200;

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
    return _col.doc(chatId).snapshots().asyncMap((doc) async {
      if (!doc.exists) return null;
      final messages = await _messageDocs(chatId).get();
      return ChatModel.fromFirestore(
        doc,
        messages: messages.docs.map(_messageFromDoc).toList(),
      );
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
      mutedFor: const [],
      blockedBy: const [],
      unreadBy: const [],
      latestMessagePreview: '',
      latestMessageSenderId: '',
      safetyStatus: 'normal',
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
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Message cannot be empty.');
    }
    if (trimmed.length > maxMessageLength) {
      throw ArgumentError('Message is too long.');
    }

    final chatRef = _col.doc(chatId);
    final messageRef = chatRef.collection('messages').doc(_uuid.v4());
    final now = FieldValue.serverTimestamp();

    await _firestore.runTransaction((transaction) async {
      final chatDoc = await transaction.get(chatRef);
      if (!chatDoc.exists) {
        throw StateError('Conversation is unavailable.');
      }

      final chat = ChatModel.fromFirestore(chatDoc);
      if (!chat.isParticipant(senderId)) {
        throw StateError('You cannot send messages in this conversation.');
      }
      if (chat.blockedBy.isNotEmpty && !chat.blockedBy.contains(senderId)) {
        throw StateError('This conversation is blocked.');
      }

      final otherParticipants =
          chat.participants.where((id) => id != senderId).toList();
      final message = {
        'id': messageRef.id,
        'conversationId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'content': trimmed,
        'status': 'delivered',
        'moderationState': 'normal',
        'createdAt': now,
        'clientCreatedAt': Timestamp.now(),
      };

      transaction.set(messageRef, message);
      transaction.update(chatRef, {
        'latestMessagePreview': _preview(trimmed),
        'latestMessageAt': now,
        'latestMessageSenderId': senderId,
        'unreadBy': FieldValue.arrayUnion(otherParticipants),
        'hiddenFor': FieldValue.arrayRemove([senderId]),
        'updatedAt': now,
      });
    });
  }

  @override
  Future<void> hideChatForUser(String chatId, String userId) async {
    await _col.doc(chatId).set({
      'hiddenFor': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> muteChatForUser(String chatId, String userId, bool muted) async {
    await _col.doc(chatId).set({
      'mutedFor': muted
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> blockChatForUser(
      String chatId, String userId, bool blocked) async {
    await _col.doc(chatId).set({
      'blockedBy': blocked
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> reportChat({
    required String chatId,
    String? messageId,
    required String reporterId,
    required String reason,
    String description = '',
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      throw ArgumentError('Report reason is required.');
    }

    final chatDoc = await _col.doc(chatId).get();
    if (!chatDoc.exists) {
      throw StateError('Conversation is unavailable.');
    }
    final chat = ChatModel.fromFirestore(chatDoc);
    if (!chat.isParticipant(reporterId)) {
      throw StateError('You cannot report this conversation.');
    }

    Map<String, dynamic>? reportedMessage;
    if (messageId != null && messageId.isNotEmpty) {
      final messageDoc =
          await _col.doc(chatId).collection('messages').doc(messageId).get();
      if (messageDoc.exists) {
        reportedMessage = _messageFromDoc(messageDoc);
      }
    }

    final reportedUserId = reportedMessage == null
        ? chat.participants.firstWhere(
            (id) => id != reporterId,
            orElse: () => '',
          )
        : ChatMessageFields.senderId(reportedMessage);

    final reportRef = _firestore.collection('reports').doc(_uuid.v4());
    final batch = _firestore.batch();
    batch.set(reportRef, {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'targetType': 'chat',
      'targetId': chatId,
      'conversationId': chatId,
      'messageId': messageId,
      'productId': chat.productId,
      'reason': normalizedReason,
      'description': description.trim(),
      'status': 'open',
      'evidenceSnapshot': {
        'productTitle': chat.productTitle,
        'buyerId': chat.buyerId,
        'sellerId': chat.sellerId,
        'latestMessagePreview': chat.safeLatestPreview,
        if (reportedMessage != null)
          'message': {
            'id': ChatMessageFields.id(reportedMessage),
            'senderId': ChatMessageFields.senderId(reportedMessage),
            'content': ChatMessageFields.content(reportedMessage),
            'createdAt': reportedMessage['createdAt'],
          },
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_col.doc(chatId), {
      'safetyStatus': 'reported',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Query<Map<String, dynamic>> _messageDocs(String chatId) =>
      _col.doc(chatId).collection('messages').orderBy('createdAt').limit(500);

  Map<String, dynamic> _messageFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return {
      ...?doc.data(),
      'id': doc.id,
    };
  }

  String _preview(String content) {
    final compact = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return compact.length <= 140 ? compact : '${compact.substring(0, 137)}...';
  }
}
