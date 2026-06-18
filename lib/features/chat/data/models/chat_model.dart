import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String productId;
  final String productTitle;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final List<Map<String, dynamic>> messages;
  final List<String> participants;
  final List<String> hiddenFor;
  final List<String> mutedFor;
  final List<String> blockedBy;
  final List<String> unreadBy;
  final String latestMessagePreview;
  final String latestMessageSenderId;
  final String safetyStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.messages,
    required this.participants,
    this.hiddenFor = const [],
    this.mutedFor = const [],
    this.blockedBy = const [],
    this.unreadBy = const [],
    this.latestMessagePreview = '',
    this.latestMessageSenderId = '',
    this.safetyStatus = 'normal',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromFirestore(
    DocumentSnapshot doc, {
    List<Map<String, dynamic>>? messages,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final legacyMessages =
        (data['messages'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    return ChatModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productTitle: data['productTitle'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      messages: messages ?? legacyMessages,
      participants:
          (data['participants'] as List<dynamic>?)?.cast<String>() ?? [],
      hiddenFor: (data['hiddenFor'] as List<dynamic>?)?.cast<String>() ?? [],
      mutedFor: (data['mutedFor'] as List<dynamic>?)?.cast<String>() ?? [],
      blockedBy: (data['blockedBy'] as List<dynamic>?)?.cast<String>() ?? [],
      unreadBy: (data['unreadBy'] as List<dynamic>?)?.cast<String>() ?? [],
      latestMessagePreview: data['latestMessagePreview'] ?? '',
      latestMessageSenderId: data['latestMessageSenderId'] ?? '',
      safetyStatus: data['safetyStatus'] ?? 'normal',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productTitle': productTitle,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'messages': messages,
      'participants': participants,
      'hiddenFor': hiddenFor,
      'mutedFor': mutedFor,
      'blockedBy': blockedBy,
      'unreadBy': unreadBy,
      'latestMessagePreview': latestMessagePreview,
      'latestMessageSenderId': latestMessageSenderId,
      'safetyStatus': safetyStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool isParticipant(String userId) => participants.contains(userId);

  String otherParticipantName(String userId) =>
      buyerId == userId ? sellerName : buyerName;

  List<Map<String, dynamic>> get orderedMessages {
    final copy = [...messages];
    copy.sort((a, b) {
      final aTime = ChatMessageFields.createdAt(a);
      final bTime = ChatMessageFields.createdAt(b);
      return aTime.compareTo(bTime);
    });
    return copy;
  }

  String get safeLatestPreview {
    if (latestMessagePreview.trim().isNotEmpty) return latestMessagePreview;
    if (messages.isEmpty) return '';
    return ChatMessageFields.content(messages.last);
  }
}

class ChatMessageFields {
  static String id(Map<String, dynamic> message) =>
      message['id']?.toString() ?? '';

  static String senderId(Map<String, dynamic> message) =>
      message['senderId']?.toString() ?? '';

  static String senderName(Map<String, dynamic> message) =>
      message['senderName']?.toString() ?? '';

  static String content(Map<String, dynamic> message) =>
      message['content']?.toString() ?? '';

  static String status(Map<String, dynamic> message) =>
      message['status']?.toString() ?? 'delivered';

  static DateTime createdAt(Map<String, dynamic> message) {
    final value = message['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
