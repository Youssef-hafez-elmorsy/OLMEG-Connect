import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  final String? imageBase64;
  
  const PostModel({
    required super.id,
    required super.authorId,
    required super.authorName,
    super.authorPhotoUrl,
    required super.description,
    required super.imageUrl,
    required super.likes,
    required super.commentCount,
    required super.createdAt,
    this.imageBase64,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      imageBase64: data['imageBase64'],
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'description': description,
        'imageUrl': imageUrl,
        'imageBase64': imageBase64,
        'likes': likes,
        'commentCount': commentCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
