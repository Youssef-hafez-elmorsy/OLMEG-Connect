import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/fullscreen_image_gallery.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';
import 'package:olmeg_connect/features/posts/services/firestore_service.dart';
import 'package:olmeg_connect/features/posts/services/user_service.dart';
import 'package:olmeg_connect/features/posts/widgets/avatar_widget.dart';
import 'package:olmeg_connect/features/posts/widgets/image_grid.dart';
import 'package:olmeg_connect/features/posts/widgets/reaction_bar.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final VoidCallback? onDelete;
  final VoidCallback? onCommentTap;

  const PostCard({
    super.key,
    required this.post,
    this.onDelete,
    this.onCommentTap,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _showComments = false;
  bool _liked = false;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _commentsCount = widget.post.commentCount;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    final postColorScheme = Theme.of(context).colorScheme;
    final postTextTheme = Theme.of(context).textTheme;
    final userActiveReaction =
        user != null ? widget.post.getActiveReaction(user.userId) : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, user),
          _buildContent(context, postTextTheme),
          if (widget.post.imageURLs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ImageGrid(
                imageURLs: widget.post.imageURLs,
                onImageTap: (index) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullscreenImageGallery(
                      images: widget.post.imageURLs,
                      initialIndex: index,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ReactionSummary(
              topReactions: widget.post.getTopReactions(),
              totalCount: widget.post.getTotalReactions(),
              commentCount: _commentsCount,
            ),
          ),
          Divider(
            height: 1,
            color: postColorScheme.outlineVariant,
          ),
          _buildActionButtons(context, user?.userId, userActiveReaction),
          if (_showComments) _buildCommentsSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserIdentity? user) {
    final post = widget.post;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                imageUrl: post.authorProfileImageUrl,
                name: post.authorName,
                avatarColor: post.authorAvatarColor,
                sizeType: AvatarSizeType.medium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.authorName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (post.feeling != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            'is feeling ${post.feeling}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          timeago.format(post.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          AudienceOptions.getIcon(post.audience),
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: post.isMadePost
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.displayType,
                  style: TextStyle(
                    color: post.isMadePost
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (post.displayPrice != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                CurrencyFormatter.egp(
                  double.tryParse(post.displayPrice ?? '0') ?? 0,
                ),
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (post.title != null && post.title!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.title!,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
          if (post.category != null && post.category!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                post.category!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, context),
                itemBuilder: (context) => [
                  if (user?.userId == post.authorId) ...[
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete Post',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const PopupMenuItem(
                      value: 'save',
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_border),
                          SizedBox(width: 8),
                          Text('Save Post'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.link),
                          SizedBox(width: 8),
                          Text('Copy Link'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Report Post'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () => _showShareSheet(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share,
                        size: 18,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, TextTheme textTheme) {
    final post = widget.post;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: post.bgColor != null
          ? Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: BackgroundGradients.getGradient(post.bgColor!),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  post.text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.text,
                    style: textTheme.bodyLarge,
                    maxLines: _liked ? null : 3,
                    overflow: _liked ? null : TextOverflow.ellipsis),
                if (post.text.length > 100 && !_liked)
                  TextButton(
                      onPressed: () => setState(() => _liked = true),
                      child: const Text('See more')),
              ],
            ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, String? currentUserId, String userActiveReaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.thumb_up,
            label: userActiveReaction.isNotEmpty ? 'Liked' : 'Like',
            isActive: userActiveReaction.isNotEmpty,
            onTap: () => _toggleReaction('like'),
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Comment',
            isActive: _showComments,
            onTap: () => setState(() {
              _showComments = !_showComments;
              if (_showComments && widget.onCommentTap != null) {
                widget.onCommentTap!();
              }
            }),
          ),
          _ActionButton(
            icon: Icons.share,
            label: 'Share',
            isActive: false,
            onTap: () => _showShareSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    return _CommentSection(
      postId: widget.post.id,
    );
  }

  void _handleMenuAction(String action, BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    switch (action) {
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this post?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete')),
            ],
          ),
        );
        if (confirm == true) {
          try {
            await FirestoreService.deletePost(widget.post.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted successfully')));
              widget.onDelete?.call();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: colorScheme.error));
            }
          }
        }
        break;
      case 'copy':
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Link copied!')));
        break;
      case 'report':
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Post reported')));
        break;
    }
  }

  void _toggleReaction(String reactionType) async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    if (user == null) return;

    try {
      await FirestoreService.toggleReaction(
          postId: widget.post.id,
          userId: user.userId,
          reactionType: reactionType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Now'),
              onTap: () {
                final link =
                    'https://olmeg-connect.web.app/posts/${widget.post.id}';
                Clipboard.setData(ClipboardData(text: link));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard!')));
              }),
          ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () {
                final link = 'https://olmeg-connect.web.app/#/feed';
                Clipboard.setData(ClipboardData(text: link));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied!')));
              }),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final currentUserProvider = FutureProvider<UserIdentity?>((ref) async {
  final userService = UserService();
  return await userService.getUser();
});

class _CommentSection extends StatefulWidget {
  final String postId;

  const _CommentSection({required this.postId});

  @override
  State<_CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<_CommentSection> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsStream = FirestoreService.getCommentsStream(widget.postId);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FutureBuilder<UserIdentity?>(
                future: UserService().getUser(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return AvatarWidget(
                      imageUrl: user?.profileImageUrl,
                      name: user?.displayName,
                      avatarColor: user?.avatarColor ?? '0xFF9E9E9E',
                      sizeType: AvatarSizeType.small);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: _addComment),
            ],
          ),
        ),
        StreamBuilder<List<CommentModel>>(
          stream: commentsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final comments = snapshot.data ?? [];
            if (comments.isEmpty) {
              return const Padding(
                  padding: EdgeInsets.all(16), child: Text('No comments yet'));
            }
            final displayComments = comments.take(3).toList();
            final remaining = comments.length - 3;
            return Column(
              children: [
                ...displayComments
                    .map((comment) => _buildCommentTile(context, comment)),
                if (remaining > 0)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Loading $remaining more comments...')),
                      );
                    },
                    child: Text('View $remaining more comments'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentTile(BuildContext context, CommentModel comment) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarWidget(
              imageUrl: comment.authorProfileImageUrl,
              name: comment.authorName,
              avatarColor: comment.authorAvatarColor,
              sizeType: AvatarSizeType.small),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.authorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(comment.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final user = await UserService().getUser();
    if (!mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }
    final comment = CommentModel(
      id: CommentModel.generateId(),
      postId: widget.postId,
      authorId: user.userId,
      authorName: user.displayName,
      authorProfileImageUrl: user.profileImageUrl,
      authorAvatarColor: user.avatarColor,
      text: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );
    try {
      await FirestoreService.addComment(comment);
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
