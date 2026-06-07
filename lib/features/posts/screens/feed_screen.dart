import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/widgets/app_brand.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';
import 'package:olmeg_connect/features/posts/services/firestore_service.dart';
import 'package:olmeg_connect/features/posts/services/user_service.dart';
import 'package:olmeg_connect/features/posts/widgets/avatar_widget.dart';
import 'package:olmeg_connect/features/posts/widgets/post_card.dart';
import 'package:olmeg_connect/features/posts/screens/create_post_screen.dart';
import 'package:olmeg_connect/features/posts/screens/profile_screen.dart';

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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: const AppBrandLockup(
          logoSize: 38,
          titleSize: 18,
          taglineSize: 11,
        ),
        actions: [
          IconButton(
            tooltip: l10n.t('createPost'),
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _navigateToCreatePost(context),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FutureBuilder<UserIdentity?>(
              future: UserService().getUser(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyPostsScreen(),
                    ),
                  ),
                  child: AvatarWidget(
                    imageUrl: user?.profileImageUrl,
                    name: user?.displayName ?? 'U',
                    avatarColor: user?.avatarColor ?? '0xFF888888',
                    sizeType: AvatarSizeType.medium,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: FirestoreService.getPostsStream(postType: _postTypeFilter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _PostFeedLoadingState();
          }

          if (snapshot.hasError) {
            return _PostFeedErrorState(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          final posts = snapshot.data ?? [];
          final filteredLabel = switch (_postTypeFilter) {
            'made' => l10n.t('made'),
            'wanted' => l10n.t('wanted'),
            _ => l10n.all,
          };

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: _FeedHero(
                    posts: posts,
                    selectedFilter: filteredLabel,
                    onCreate: () => _navigateToCreatePost(context),
                    onMyPosts: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyPostsScreen(),
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterHeaderDelegate(
                    child: Container(
                      color: colorScheme.surface,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: _buildFilterRow(context),
                    ),
                  ),
                ),
                if (posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _PostFeedEmptyState(
                      filter: filteredLabel,
                      onCreate: () => _navigateToCreatePost(context),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AnimatedFilterChip(
            icon: Icons.dynamic_feed_outlined,
            label: AppLocalizations.of(context).all,
            isSelected: _postTypeFilter == 'all',
            onTap: () => setState(() => _postTypeFilter = 'all'),
          ),
          const SizedBox(width: 8),
          _AnimatedFilterChip(
            icon: Icons.handyman_outlined,
            label: AppLocalizations.of(context).t('made'),
            isSelected: _postTypeFilter == 'made',
            onTap: () => setState(() => _postTypeFilter = 'made'),
          ),
          const SizedBox(width: 8),
          _AnimatedFilterChip(
            icon: Icons.search_outlined,
            label: AppLocalizations.of(context).t('wanted'),
            isSelected: _postTypeFilter == 'wanted',
            onTap: () => setState(() => _postTypeFilter = 'wanted'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreatePost(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()));
  }
}

class _FeedHero extends StatelessWidget {
  final List<PostModel> posts;
  final String selectedFilter;
  final VoidCallback onCreate;
  final VoidCallback onMyPosts;

  const _FeedHero({
    required this.posts,
    required this.selectedFilter,
    required this.onCreate,
    required this.onMyPosts,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final madeCount = posts.where((post) => post.isMadePost).length;
    final wantedCount = posts.where((post) => post.isWantedPost).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('communityPosts'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.t('communityPostsMessage'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.8),
                      ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.t('create')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: l10n.t('myPosts'),
                      onPressed: onMyPosts,
                      icon: const Icon(Icons.person_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FeedStat(label: selectedFilter, value: posts.length.toString()),
              const SizedBox(width: 8),
              _FeedStat(label: l10n.t('made'), value: madeCount.toString()),
              const SizedBox(width: 8),
              _FeedStat(label: l10n.t('wanted'), value: wantedCount.toString()),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<UserIdentity?>(
            future: UserService().getUser(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return _ComposerShortcut(
                user: user,
                onTap: onCreate,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeedStat extends StatelessWidget {
  final String label;
  final String value;

  const _FeedStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerShortcut extends StatelessWidget {
  final UserIdentity? user;
  final VoidCallback onTap;

  const _ComposerShortcut({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              AvatarWidget(
                imageUrl: user?.profileImageUrl,
                name: user?.displayName ?? 'U',
                avatarColor: user?.avatarColor ?? '0xFF888888',
                sizeType: AvatarSizeType.medium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.t('postPrompt'),
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              const Icon(Icons.add_photo_alternate_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _FilterHeaderDelegate({required this.child});

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _PostFeedLoadingState extends StatelessWidget {
  const _PostFeedLoadingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: index == 0 ? 190 : 130,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    );
  }
}

class _PostFeedErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _PostFeedErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.t('errorLoadingPosts'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostFeedEmptyState extends StatelessWidget {
  final String filter;
  final VoidCallback onCreate;

  const _PostFeedEmptyState({required this.filter, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(l10n.noPostsYet(filter),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.t('emptyPostMessage'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.t('createPost')),
            ),
          ],
        ),
      ),
    );
  }
}

// ويدجت أزرار التنقل مع أنيميشن بسيط
// ويدجت الفلتر مع أنيميشن التكبير واللون
class _AnimatedFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedFilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
