import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';
import 'package:olmeg_connect/features/posts/services/firestore_service.dart';
import 'package:olmeg_connect/features/posts/services/user_service.dart';
import 'package:olmeg_connect/features/posts/widgets/avatar_widget.dart';

class PostCommentsScreen extends StatefulWidget {
  final PostModel post;

  const PostCommentsScreen({super.key, required this.post});

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('comments'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.post.title?.trim().isNotEmpty == true
                    ? widget.post.title!.trim()
                    : widget.post.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: FirestoreService.getCommentsStream(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data ?? const [];
                if (comments.isEmpty) {
                  return Center(child: Text(l10n.t('noCommentsYet')));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AvatarWidget(
                          imageUrl: comment.authorProfileImageUrl,
                          name: comment.authorName,
                          avatarColor: comment.authorAvatarColor,
                          sizeType: AvatarSizeType.small,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(comment.text),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: l10n.t('writeComment'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.t('sendComment'),
                    icon: Icon(Icons.send, color: colorScheme.primary),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
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
      postId: widget.post.id,
      authorId: user.userId,
      authorName: user.displayName,
      authorProfileImageUrl: user.profileImageUrl,
      authorAvatarColor: user.avatarColor,
      text: text,
      createdAt: DateTime.now(),
    );
    await FirestoreService.addComment(comment);
    _commentController.clear();
  }
}
