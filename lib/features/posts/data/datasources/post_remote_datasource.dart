import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/post_model.dart';

abstract class PostRemoteDataSource {
  Future<List<PostModel>> getPosts();
  Future<void> createPost({required String authorId, required String authorName, required String? authorPhotoUrl, required String description, required File image});
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
  Future<void> createPost({required String authorId, required String authorName, required String? authorPhotoUrl, required String description, required File image}) async {
    final imageId = _uuid.v4();
    final ref = _storage.ref().child('${AppConstants.postImagesPath}/$imageId.jpg');
    await ref.putFile(image);
    final imageUrl = await ref.getDownloadURL();
    final model = PostModel(id: _uuid.v4(), authorId: authorId, authorName: authorName, authorPhotoUrl: authorPhotoUrl, description: description, imageUrl: imageUrl, likes: const [], commentCount: 0, createdAt: DateTime.now());
    await _col.doc(model.id).set(model.toFirestore());
  }

  @override
  Future<void> toggleLike({required String postId, required String userId}) async {
    final doc = await _col.doc(postId).get();
    final data = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? []);
    if (likes.contains(userId)) { likes.remove(userId); } else { likes.add(userId); }
    await _col.doc(postId).update({'likes': likes});
  }
}
