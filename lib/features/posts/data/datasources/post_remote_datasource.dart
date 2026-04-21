import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/post_model.dart';

abstract class PostRemoteDataSource {
  Future<List<PostModel>> getPosts();
  Future<void> createPost({
    required String authorId, 
    required String authorName, 
    required String? authorPhotoUrl, 
    required String description, 
    Uint8List? imageBytes,
  });
  Future<void> toggleLike({required String postId, required String userId});
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  PostRemoteDataSourceImpl({required FirebaseFirestore firestore, required FirebaseStorage storage})
      : _firestore = firestore, _storage = storage;

  CollectionReference get _col => _firestore.collection(AppConstants.postsCollection);

  @override
  Future<List<PostModel>> getPosts() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String description,
    Uint8List? imageBytes,
  }) async {
    try {
      print('[Post] Creating post with Base64 image...');
      
      String? imageBase64;
      String? imageUrl;
      
      if (imageBytes != null && imageBytes.isNotEmpty) {
        // Convert bytes to Base64
        imageBase64 = base64Encode(imageBytes);
        print('[Post] Image converted to Base64, size: ${imageBytes.length} bytes');
      }
      
      // Create post with Base64 image stored in Firestore
      final model = PostModel(
        id: _uuid.v4(),
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        description: description,
        imageUrl: imageUrl ?? '',
        imageBase64: imageBase64,
        likes: const [],
        commentCount: 0,
        createdAt: DateTime.now(),
      );
      
      await _col.doc(model.id).set(model.toFirestore());
      print('[Post] Post saved to Firestore with Base64 image');
      
    } catch (e) {
      print('[Post] Error creating post: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleLike({required String postId, required String userId}) async {
    final doc = await _col.doc(postId).get();
    final data = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? []);
    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
    await _col.doc(postId).update({'likes': likes});
  }
}
