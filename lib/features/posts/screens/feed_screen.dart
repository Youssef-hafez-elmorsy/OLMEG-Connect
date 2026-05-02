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
  String _postTypeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110, // زيادة الطول لتكفي العناصر الجديدة
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // السطر الأول: العنوان والبروفايل
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Olmeg Connect', style: TextStyle(fontWeight: FontWeight.bold)),
                FutureBuilder<UserIdentity?>(
                  future: UserService().getUser(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return user != null
                        ? AvatarWidget(
                            name: user.displayName,
                            avatarColor: user.avatarColor,
                            radius: 18,
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // السطر الثاني: شريط التنقل (Home, Create, Profile)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavButton(icon: Icons.home, label: 'Home', isActive: true, onTap: () {}),
                _NavButton(
                  icon: Icons.add_circle_outline,
                  label: 'Create',
                  isActive: false,
                  onTap: () => _navigateToCreatePost(context),
                ),
                _NavButton(icon: Icons.person_outline, label: 'Profile', isActive: false, onTap: () {}),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 12, right: 12),
            child: _buildFilterRow(context),
          ),
        ),
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: FirestoreService.getPostsStream(postType: _postTypeFilter),
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

  Widget _buildFilterRow(BuildContext context) {
    return Row(
      children: [
        _AnimatedFilterChip(
          label: 'All',
          isSelected: _postTypeFilter == 'all',
          onTap: () => setState(() => _postTypeFilter = 'all'),
        ),
        const SizedBox(width: 8),
        _AnimatedFilterChip(
          label: 'Made',
          isSelected: _postTypeFilter == 'made',
          onTap: () => setState(() => _postTypeFilter = 'made'),
        ),
        const SizedBox(width: 8),
        _AnimatedFilterChip(
          label: 'Wanted',
          isSelected: _postTypeFilter == 'wanted',
          onTap: () => setState(() => _postTypeFilter = 'wanted'),
        ),
      ],
    );
  }

  Widget _buildCreatePostShortcut(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FutureBuilder<UserIdentity?>(
                future: UserService().getUser(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return AvatarWidget(
                    name: user?.displayName ?? "U",
                    avatarColor: user?.avatarColor ?? "0xFF888888",
                    radius: 20,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _navigateToCreatePost(context),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text("What's on your mind?", 
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
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

// ويدجت أزرار التنقل مع أنيميشن بسيط
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ويدجت الفلتر مع أنيميشن التكبير واللون
class _AnimatedFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: 1,
            ),
            boxShadow: isSelected 
              ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}