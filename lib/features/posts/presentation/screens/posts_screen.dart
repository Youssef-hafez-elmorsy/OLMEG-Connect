import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/post_model.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/posts_provider.dart';

class PostsScreen extends ConsumerWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Handmade Feed')),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No posts yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/create-post'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Post'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _PostCard(post: post);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Error loading posts: $error', style: TextStyle(color: Colors.red.shade400)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.refresh(postsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-post'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostEntity post;

  const _PostCard({required this.post});

  String? _getBase64Image() {
    if (post is PostModel) {
      return (post as PostModel).imageBase64;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: post.authorPhotoUrl != null && post.authorPhotoUrl!.startsWith('http')
                          ? NetworkImage(post.authorPhotoUrl!)
                          : null,
                      child: post.authorPhotoUrl == null || !post.authorPhotoUrl!.startsWith('http')
                          ? Text(post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U')
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(post.description),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('${post.likes.length}'),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('${post.commentCount}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    // Try Base64 first
    final base64Image = _getBase64Image();
    
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Image);
        debugPrint('Displaying Base64 image, size: ${bytes.length} bytes');
        return Image.memory(
          bytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Base64 image error: $error');
            return _buildPlaceholder('Invalid image');
          },
        );
      } catch (e) {
        debugPrint('Error decoding Base64: $e');
        return _buildPlaceholder('Decode error');
      }
    }
    
    // Fallback to network URL
    if (post.imageUrl.isNotEmpty && post.imageUrl.startsWith('http')) {
      return Image.network(
        post.imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder('Network error'),
      );
    }
    
    return _buildPlaceholder('No image');
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
