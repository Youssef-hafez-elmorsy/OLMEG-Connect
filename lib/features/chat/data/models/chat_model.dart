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
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productTitle: data['productTitle'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      messages:
          (data['messages'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [],
      participants:
          (data['participants'] as List<dynamic>?)?.cast<String>() ?? [],
      hiddenFor: (data['hiddenFor'] as List<dynamic>?)?.cast<String>() ?? [],
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
