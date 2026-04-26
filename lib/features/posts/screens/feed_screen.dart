import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';
import 'package:olmeg_connect/features/posts/services/firestore_service.dart';
import 'package:olmeg_connect/features/posts/services/user_service.dart';
import 'package:olmeg_connect/features/posts/widgets/avatar_widget.dart';
import 'package:olmeg_connect/features/posts/widgets/post_card.dart';
import 'package:olmeg_connect/features/posts/screens/create_post_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Olmeg Connect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.gamepad),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _DemoPostsView()),
            ),
            tooltip: 'Demo',
          ),
          FutureBuilder<UserIdentity?>(
            future: UserService().getUser(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return user != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AvatarWidget(name: user.displayName, avatarColor: user.avatarColor, radius: 16),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: FirestoreService.getPostsStream(),
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildCreatePostShortcut(context)),
                if (posts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.article_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No posts yet', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToCreatePost(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Post'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = posts[index];
                        return PostCard(
                          key: ValueKey(post.id),
                          post: post,
                          onDelete: () {},
                        );
                      },
                      childCount: posts.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoriesRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 6,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outline, width: 2),
                    ),
                    child: Icon(Icons.add, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text('Add', style: theme.textTheme.bodySmall),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.transparent, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    radius: 26,
                    child: Text('U$index', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 4),
                Text('User $index', style: theme.textTheme.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreatePostShortcut(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FutureBuilder<UserIdentity?>(
                future: UserService().getUser(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return user != null
                      ? AvatarWidget(name: user.displayName, avatarColor: user.avatarColor, radius: 20)
                      : CircleAvatar(radius: 20);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _navigateToCreatePost(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("What's on your mind?", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreatePost(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
  }
}

class _DemoPostsView extends StatelessWidget {
  const _DemoPostsView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Demo'),
        backgroundColor: colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text('وضع التجربة', style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'هذا وضع محاكاة لتجربة التطبيق',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDemoPost(
            context,
            authorName: 'أحمد محمد',
            authorColor: '0xFFE53935',
            text: 'مرحباً! هذا منشور تجريبي. اضغط على زر "Share" للمشاركة! 👆',
            feeling: '😊 Happy',
            hoursAgo: 2,
            audience: 'public',
          ),
          const SizedBox(height: 16),
          _buildDemoPost(
            context,
            authorName: 'سارة علي',
            authorColor: '0xFF5E35B1',
            text: 'منظر جميل من الطبيعة! 🌄',
            imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
            hoursAgo: 5,
            audience: 'friends',
          ),
          const SizedBox(height: 16),
          _buildDemoPost(
            context,
            authorName: 'محمد خالد',
            authorColor: '0xFF1E88E5',
            text: 'يوم جميل للتفكير الإيجابي! ✨',
            bgColor: 'sunset',
            hoursAgo: 8,
            audience: 'public',
          ),
          const SizedBox(height: 16),
          _buildDemoPost(
            context,
            authorName: 'فاطمة عمر',
            authorColor: '0xFF43A047',
            text: 'عائلة سعيدة! ❤️',
            imageUrls: [
              'https://images.unsplash.com/photo-1511895426328-dc8714191300?w=400',
              'https://images.unsplash.com/photo-1516627145497-ae6968895b74?w=400',
              'https://images.unsplash.com/photo-1504439468489-c8920d796a29?w=400',
            ],
            hoursAgo: 12,
            audience: 'friends',
          ),
        ],
      ),
    );
  }

  Widget _buildDemoPost(
    BuildContext context, {
    required String authorName,
    required String authorColor,
    required String text,
    String? feeling,
    String? imageUrl,
    List<String>? imageUrls,
    String? bgColor,
    required int hoursAgo,
    required String audience,
  }) {
    final images = <String>[];
    if (imageUrl != null) images.add(imageUrl);
    if (imageUrls != null) images.addAll(imageUrls);

    final post = PostModel(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'demo_user',
      authorName: authorName,
      authorAvatarColor: authorColor,
      text: text,
      bgColor: bgColor,
      feeling: feeling,
      imageURLs: images,
      audience: audience,
      createdAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
      reactions: {'like': ['user1', 'user2'], 'love': ['user3']},
      commentCount: 5,
    );

    return PostCard(
      post: post,
      onDelete: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ تم حذف المنشور')),
      ),
    );
  }
}