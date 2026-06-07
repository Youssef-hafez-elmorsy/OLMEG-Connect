import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:olmeg_connect/core/constants/app_constants.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/services/promotion_request_service.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/features/chat/presentation/providers/chat_provider.dart';
import 'package:olmeg_connect/core/widgets/fullscreen_image_gallery.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';
import 'package:olmeg_connect/features/posts/screens/post_comments_screen.dart';
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
  final bool _showComments = false;
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: postColorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: postColorScheme.outlineVariant),
      ),
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
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
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
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: post.isMadePost
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: post.isMadePost
                        ? Colors.green.withValues(alpha: 0.28)
                        : Colors.orange.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  l10n.postTypeLabel(post.postType ?? 'made'),
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
          if (post.displayPrice != null || post.category != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (post.displayPrice != null)
                  _PostMetaPill(
                    icon: Icons.sell_outlined,
                    label: CurrencyFormatter.egp(
                      double.tryParse(post.displayPrice ?? '0') ?? 0,
                    ),
                  ),
                if (post.category != null && post.category!.isNotEmpty)
                  _PostMetaPill(
                    icon: Icons.category_outlined,
                    label: l10n.categoryLabel(post.category!),
                  ),
              ],
            ),
          ],
          if (post.title != null && post.title!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              post.title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
            ),
          ],
          if (post.location != null && post.location!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    post.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
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
                    PopupMenuItem(
                      value: 'sponsor',
                      child: Row(
                        children: [
                          const Icon(Icons.campaign_outlined),
                          const SizedBox(width: 8),
                          Text(l10n.t('sponsorPost')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            l10n.t('deletePost'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    PopupMenuItem(
                      value: 'save',
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark_border),
                          const SizedBox(width: 8),
                          Text(l10n.t('savePost')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          const Icon(Icons.link),
                          const SizedBox(width: 8),
                          Text(l10n.t('copyLink')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(Icons.flag, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(l10n.t('reportPost')),
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
                        l10n.t('share'),
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
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: post.bgColor != null
          ? Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: BackgroundGradients.getGradient(post.bgColor!),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
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
                    style: textTheme.bodyLarge?.copyWith(height: 1.45),
                    maxLines: _liked ? null : 3,
                    overflow: _liked ? null : TextOverflow.ellipsis),
                if (post.text.length > 100 && !_liked)
                  TextButton(
                      onPressed: () => setState(() => _liked = true),
                      child: Text(l10n.t('seeMore'))),
              ],
            ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, String? currentUserId, String userActiveReaction) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 4,
        children: [
          _ActionButton(
            icon: Icons.thumb_up,
            label: userActiveReaction.isNotEmpty
                ? l10n.t('liked')
                : l10n.t('like'),
            isActive: userActiveReaction.isNotEmpty,
            onTap: () => _toggleReaction('like'),
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: l10n.t('comment'),
            isActive: false,
            onTap: () => _openComments(context),
          ),
          _ActionButton(
            icon: Icons.forum_outlined,
            label: l10n.chat,
            isActive: false,
            onTap: () => _joinPostChat(context, currentUserId),
          ),
          _ActionButton(
            icon: Icons.share,
            label: l10n.t('share'),
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
      post: widget.post,
    );
  }

  void _openComments(BuildContext context) {
    widget.onCommentTap?.call();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostCommentsScreen(post: widget.post),
      ),
    );
  }

  Future<void> _joinPostChat(
      BuildContext context, String? currentUserId) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('pleaseSignInToChat')),
        ),
      );
      return;
    }
    if (currentUserId == widget.post.authorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).t('youOwnThisPost'))),
      );
      return;
    }
    final user = ref.read(currentUserProvider).value;
    final buyerName = user?.displayName ?? 'Marketplace user';
    final chatId = await ref.read(chatNotifierProvider.notifier).createChat(
          productId: 'post_${widget.post.id}',
          productTitle: widget.post.title?.trim().isNotEmpty == true
              ? widget.post.title!.trim()
              : AppLocalizations.of(context).t('postChat'),
          buyerId: currentUserId,
          buyerName: buyerName,
          sellerId: widget.post.authorId,
          sellerName: widget.post.authorName,
        );
    if (chatId == null || !context.mounted) return;
    final chat =
        await ref.read(chatRemoteDataSourceProvider).getChatById(chatId);
    if (chat != null && context.mounted) {
      context.push('/chat/$chatId', extra: chat);
    }
  }

  void _handleMenuAction(String action, BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case 'sponsor':
        final user = ref.read(currentUserProvider).value;
        if (user == null) return;
        await PromotionRequestService.showPromotionSheet(
          context: context,
          ownerId: user.userId,
          targetId: widget.post.id,
          targetTitle: widget.post.title?.trim().isNotEmpty == true
              ? widget.post.title!.trim()
              : widget.post.text,
          targetType: 'post',
        );
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.t('deleteThisPost')),
            content: Text(l10n.t('cannotBeUndone')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel)),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l10n.delete)),
            ],
          ),
        );
        if (confirm == true) {
          try {
            await FirestoreService.deletePost(widget.post.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.t('postDeletedSuccessfully'))),
              );
              widget.onDelete?.call();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.errorWithMessage(e)),
                  backgroundColor: colorScheme.error));
            }
          }
        }
        break;
      case 'copy':
        await Clipboard.setData(
          ClipboardData(text: AppConstants.postShareUrl(widget.post.id)),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.t('linkCopied'))));
        }
        break;
      case 'report':
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.t('postReported'))));
        break;
    }
  }

  void _toggleReaction(String reactionType) async {
    final l10n = AppLocalizations.of(context);
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
            .showSnackBar(SnackBar(content: Text(l10n.errorWithMessage(e))));
      }
    }
  }

  void _showShareSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              leading: const Icon(Icons.share),
              title: Text(l10n.t('shareNow')),
              onTap: () {
                final link = AppConstants.postShareUrl(widget.post.id);
                Clipboard.setData(ClipboardData(text: link));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.t('linkCopiedToClipboard'))),
                );
              }),
          ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.t('copyLink')),
              onTap: () {
                final link = AppConstants.feedShareUrl();
                Clipboard.setData(ClipboardData(text: link));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.t('linkCopied'))),
                );
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
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

class _PostMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PostMetaPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
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
  final PostModel post;

  const _CommentSection({required this.postId, required this.post});

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
    final l10n = AppLocalizations.of(context);

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
                    hintText: l10n.t('writeComment'),
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
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.t('noCommentsYet')),
              );
            }
            final displayComments = comments.take(3).toList();
            final remaining = comments.length - 3;
            return Column(
              children: [
                ...displayComments
                    .map((comment) => _buildCommentTile(context, comment)),
                if (remaining > 0)
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PostCommentsScreen(post: widget.post),
                      ),
                    ),
                    child: Text(l10n.postMoreComments(remaining)),
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
        SnackBar(
          content: Text(AppLocalizations.of(context).t('signInToComment')),
        ),
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
          SnackBar(
              content: Text(AppLocalizations.of(context).t('commentAdded'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).errorWithMessage(e))),
        );
      }
    }
  }
}
