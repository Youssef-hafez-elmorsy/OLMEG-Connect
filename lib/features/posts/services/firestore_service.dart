import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static CollectionReference get _postsRef => _firestore.collection('posts');
  
  static Stream<List<PostModel>> getPostsStream({int limit = 20, DocumentSnapshot? lastDoc}) {
    Query query = _postsRef.orderBy('createdAt', descending: true).limit(limit);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    return query.snapshots().map((snap) => snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  static Stream<List<PostModel>> getUserPostsStream(String authorId) {
    return _postsRef.where('authorId', isEqualTo: authorId).orderBy('createdAt', descending: true).snapshots().map((snap) => snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  static Future<void> createPost(PostModel post) async {
    await _postsRef.doc(post.id).set(post.toMap());
  }

  static Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await _postsRef.doc(postId).update(data);
  }

  static Future<void> deletePost(String postId) async {
    final post = await _postsRef.doc(postId).get();
    if (post.exists) {
      final postData = post.data() as Map<String, dynamic>;
      final imageURLs = List<String>.from(postData['imageURLs'] ?? []);
      
      for (final url in imageURLs) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }
      
      final comments = await _postsRef.doc(postId).collection('comments').get();
      for (final comment in comments.docs) {
        await comment.reference.delete();
      }
      
      await _postsRef.doc(postId).delete();
    }
  }

  static Future<void> toggleReaction({
    required String postId,
    required String userId,
    required String reactionType,
  }) async {
    final postRef = _postsRef.doc(postId);
    final post = await postRef.get();
    if (!post.exists) return;

    final data = post.data() as Map<String, dynamic>;
    final reactions = Map<String, List<String>>.from(
      (data['reactions'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v ?? [])),
      ) ?? {},
    );

    final currentList = reactions[reactionType] ?? [];
    
    if (currentList.contains(userId)) {
      await postRef.update({
        'reactions.$reactionType': FieldValue.arrayRemove([userId])
      });
    } else {
      for (final key in reactions.keys) {
        if (reactions[key]?.contains(userId) ?? false) {
          await postRef.update({
            'reactions.$key': FieldValue.arrayRemove([userId])
          });
        }
      }
      await postRef.update({
        'reactions.$reactionType': FieldValue.arrayUnion([userId])
      });
    }
  }

  static CollectionReference commentsRef(String postId) => _postsRef.doc(postId).collection('comments');

  static Stream<List<CommentModel>> getCommentsStream(String postId) {
    return commentsRef(postId).orderBy('createdAt').snapshots().map((snap) => snap.docs.map((doc) => CommentModel.fromFirestore(postId, doc)).toList());
  }

  static Future<void> addComment(CommentModel comment) async {
    await commentsRef(comment.postId).doc(comment.id).set(comment.toMap());
    await _postsRef.doc(comment.postId).update({'commentCount': FieldValue.increment(1)});
  }

  static Future<void> deleteComment(String postId, String commentId) async {
    await commentsRef(postId).doc(commentId).delete();
    await _postsRef.doc(postId).update({'commentCount': FieldValue.increment(-1)});
  }

  static Future<String> uploadImage(XFile file, String authorId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${timestamp}_${file.name.replaceAll(RegExp(r'[^\w\s.-]'), '_')}';
    
    if (kIsWeb) {
      try {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final ext = _getImageExtension(file.name);
        return 'data:image/$ext;base64,$base64String';
      } catch (e) {
        debugPrint('Web upload error: $e');
        return '';
      }
    } else {
      final path = 'posts/$authorId/$fileName';
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(File(file.path));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    }
  }
  
  static String _getImageExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
      return ext;
    }
    return 'jpeg';
  }

  static Future<List<String>> uploadImages(List<XFile> files, String authorId) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadImage(file, authorId);
      urls.add(url);
    }
    return urls;
  }
}

class AudienceOptions {
  static const Map<String, IconData> options = {
    'public': Icons.public,
    'friends': Icons.people,
    'only_me': Icons.lock,
  };

  static IconData getIcon(String audience) {
    return options[audience] ?? Icons.public;
  }
}