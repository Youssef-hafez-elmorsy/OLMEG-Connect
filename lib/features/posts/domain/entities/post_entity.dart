import 'package:equatable/equatable.dart';

class PostEntity extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String description;
  final String imageUrl;
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;

  const PostEntity({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.description,
    required this.imageUrl,
    required this.likes,
    required this.commentCount,
    required this.createdAt,
  });

  bool isLikedBy(String userId) => likes.contains(userId);

  @override
  List<Object?> get props => [id, authorId, likes, commentCount];
}
