import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarColor;
  final String text;
  final String? postType; // "made" | "wanted" - null means old post, treat as "made"
  final String? title;
  final String? description;
  final String? category;
  final double? price;
  final double? budget;
  final String? bgColor;
  final String? feeling;
  final String? location;
  final List<String> imageURLs;
  final String audience;
  final DateTime createdAt;
  final Map<String, List<String>> reactions;
  final int commentCount;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarColor,
    required this.text,
    this.postType,
    this.title,
    this.description,
    this.category,
    this.price,
    this.budget,
    this.bgColor,
    this.feeling,
    this.location,
    required this.imageURLs,
    required this.audience,
    required this.createdAt,
    required this.reactions,
    required this.commentCount,
  });

  bool get isMadePost => postType == null || postType == 'made';
  bool get isWantedPost => postType == 'wanted';
  String get displayType => isMadePost ? 'For Sale' : 'Request';
  String? get displayPrice => isMadePost ? price?.toStringAsFixed(0) : budget?.toStringAsFixed(0);

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatarColor: data['authorAvatarColor'] ?? '0xFF9E9E9E',
      text: data['text'] ?? '',
      postType: data['postType'],
      title: data['title'],
      description: data['description'],
      category: data['category'],
      price: data['price']?.toDouble(),
      budget: data['budget']?.toDouble(),
      bgColor: data['bgColor'],
      feeling: data['feeling'],
      location: data['location'],
      imageURLs: data['imageURLs'] != null 
          ? List<String>.from(data['imageURLs']) 
          : [],
      audience: data['audience'] ?? 'public',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: Map<String, List<String>>.from(
        (data['reactions'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, List<String>.from(v ?? [])),
        ) ?? {},
      ),
      commentCount: data['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarColor': authorAvatarColor,
      'text': text,
      'postType': postType,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'budget': budget,
      'bgColor': bgColor,
      'feeling': feeling,
      'location': location,
      'imageURLs': imageURLs,
      'audience': audience,
      'createdAt': Timestamp.fromDate(createdAt),
      'reactions': reactions,
      'commentCount': commentCount,
    };
  }

  static String generateId() => const Uuid().v4();

  int getReactionCount(String reactionType) {
    return reactions[reactionType]?.length ?? 0;
  }

  bool hasUserReacted(String userId, String reactionType) {
    return reactions[reactionType]?.contains(userId) ?? false;
  }

  String getActiveReaction(String userId) {
    for (final entry in reactions.entries) {
      if (entry.value.contains(userId)) {
        return entry.key;
      }
    }
    return '';
  }

  int getTotalReactions() {
    int total = 0;
    for (final list in reactions.values) {
      total += list.length;
    }
    return total;
  }

  List<String> getTopReactions() {
    final List<String> top = [];
    if (getReactionCount('like') > 0) top.add('👍');
    if (getReactionCount('love') > 0) top.add('❤️');
    if (getReactionCount('haha') > 0) top.add('😂');
    if (getReactionCount('wow') > 0) top.add('😮');
    if (getReactionCount('sad') > 0) top.add('😢');
    if (getReactionCount('angry') > 0) top.add('😡');
    return top;
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatarColor;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarColor,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(String postId, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: postId,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatarColor: data['authorAvatarColor'] ?? '0xFF9E9E9E',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarColor': authorAvatarColor,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static String generateId() => const Uuid().v4();
}

class UserIdentity {
  final String userId;
  final String displayName;
  final String avatarColor;

  UserIdentity({
    required this.userId,
    required this.displayName,
    required this.avatarColor,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'avatarColor': avatarColor,
  };

  factory UserIdentity.fromJson(Map<String, dynamic> json) {
    return UserIdentity(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      avatarColor: json['avatarColor'] ?? '0xFF9E9E9E',
    );
  }
}