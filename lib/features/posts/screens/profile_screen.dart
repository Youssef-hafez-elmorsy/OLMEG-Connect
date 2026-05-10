import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';
import 'package:olmeg_connect/features/posts/services/firestore_service.dart';
import 'package:olmeg_connect/features/posts/services/user_service.dart';
import 'package:olmeg_connect/features/posts/widgets/avatar_widget.dart';
import 'package:olmeg_connect/features/posts/widgets/post_card.dart';
import 'package:olmeg_connect/features/posts/screens/create_post_screen.dart';
import 'package:olmeg_connect/features/profile/presentation/screens/edit_profile_screen.dart';

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
          }),
        ],
      ),
      body: FutureBuilder<UserIdentity?>(
        future: UserService().getUser(),
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          if (!userSnapshot.hasData || user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<PostModel>>(
            stream: FirestoreService.getUserPostsStream(user.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text("You haven't posted anything yet", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToCreatePost(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Post'),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildUserHeader(context, user, posts.length)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = posts[index];
                        return PostCard(key: ValueKey(post.id), post: post, onDelete: () {});
                      },
                      childCount: posts.length,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreatePost(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, UserIdentity user, int postCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AvatarWidget(imageUrl: user.profileImageUrl, name: user.displayName, avatarColor: user.avatarColor, sizeType: AvatarSizeType.large),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('$postCount posts', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreatePost(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
  }
}