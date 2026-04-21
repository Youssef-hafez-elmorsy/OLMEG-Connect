import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/post_remote_datasource.dart';
import '../../domain/entities/post_entity.dart';

final postRemoteDataSourceProvider = Provider<PostRemoteDataSource>((ref) {
  return PostRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

final postsProvider = FutureProvider<List<PostEntity>>((ref) async {
  final ds = ref.watch(postRemoteDataSourceProvider);
  return ds.getPosts();
});

class PostsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String?> createPost({
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String description,
    Uint8List? imageBytes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(postRemoteDataSourceProvider).createPost(
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        description: description,
        imageBytes: imageBytes,
      );
      state = const AsyncValue.data(null);
      return null;
    } catch (e) {
      state = const AsyncValue.data(null);
      return e.toString();
    }
  }

  Future<void> toggleLike({required String postId, required String userId}) async {
    await ref.read(postRemoteDataSourceProvider).toggleLike(postId: postId, userId: userId);
  }
}

final postsNotifierProvider = NotifierProvider<PostsNotifier, AsyncValue<void>>(() {
  return PostsNotifier();
});
