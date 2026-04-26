import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';
import 'package:olmeg_connect/features/posts/services/firestore_service.dart';
import 'package:olmeg_connect/features/posts/services/user_service.dart';
import 'package:olmeg_connect/features/posts/widgets/avatar_widget.dart';
import 'package:olmeg_connect/features/posts/widgets/image_preview_grid.dart';
import 'package:olmeg_connect/features/posts/widgets/post_card.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _textController = TextEditingController();
  List<XFile> _selectedImages = [];
  List<double> _uploadProgress = [];
  String _audience = 'public';
  String? _bgColor;
  String? _feeling;
  String? _location;
  bool _isPosting = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        leading: GestureDetector(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _canPost() && !_isPosting ? _handlePost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.surfaceContainerHighest,
              ),
              child: _isPosting
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserHeader(context),
                  _buildAudienceRow(context),
                  _buildTextField(context),
                  if (_selectedImages.isNotEmpty) _buildImagePreview(context),
                  _buildAttachmentOptions(context),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _canPost() && !_isPosting ? _handlePost : null,
                  icon: _isPosting
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                      : const Icon(Icons.send, size: 24),
                  label: Text(
                    _isPosting ? 'Publishing...' : 'Publish Post',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return FutureBuilder<UserIdentity?>(
      future: UserService().getUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AvatarWidget(name: user?.displayName, avatarColor: user?.avatarColor ?? '0xFF9E9E9E', radius: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? 'User', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    if (_feeling != null)
                      Text(_feeling!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudienceRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          PopupMenuButton<String>(
            initialValue: _audience,
            onSelected: (value) => setState(() => _audience = value),
            child: Row(
              children: [
                Icon(AudienceOptions.getIcon(_audience), size: 18, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(_audience == 'public' ? 'Public' : _audience == 'friends' ? 'Friends' : 'Only Me', style: TextStyle(color: colorScheme.primary)),
                Icon(Icons.expand_more, size: 18, color: colorScheme.primary),
              ],
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'public', child: Row(children: [Icon(Icons.public), SizedBox(width: 8), Text('Public')])),
              const PopupMenuItem(value: 'friends', child: Row(children: [Icon(Icons.people), SizedBox(width: 8), Text('Friends')])),
              const PopupMenuItem(value: 'only_me', child: Row(children: [Icon(Icons.lock), SizedBox(width: 8), Text('Only Me')])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = _textController.text;

    if (_bgColor != null) {
      return Container(
        margin: const EdgeInsets.all(12),
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: BackgroundGradients.getGradient(_bgColor!),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: TextField(
            controller: _textController,
            maxLines: null,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _textController,
            maxLines: null,
            minLines: 3,
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          Text('${text.length}/500', style: TextStyle(color: text.length > 450 ? colorScheme.error : colorScheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ImagePreviewGrid(
        images: _selectedImages,
        uploadProgress: _uploadProgress.isNotEmpty ? _uploadProgress : null,
        onRemove: (index) {
          setState(() {
            _selectedImages.removeAt(index);
            if (_uploadProgress.length > index) _uploadProgress.removeAt(index);
          });
        },
      ),
    );
  }

  Widget _buildAttachmentOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _AttachmentButton(icon: Icons.photo, label: 'Photo', onTap: _pickImages),
            _AttachmentButton(icon: Icons.tag, label: 'Tag', onTap: _showTagSheet),
            _AttachmentButton(icon: Icons.emoji_emotions, label: 'Feeling', onTap: _showFeelingSheet),
            _AttachmentButton(icon: Icons.location_on, label: 'Location', onTap: _showLocationSheet),
            _AttachmentButton(icon: Icons.format_color_fill, label: 'Background', onTap: _showBackgroundSheet),
          ],
        ),
      ),
    );
  }

  bool _canPost() {
    return _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images;
        _uploadProgress = List.filled(_selectedImages.length, 0.0);
      });
    }
  }

  void _showTagSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tag someone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(hintText: 'Enter name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              onSubmitted: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tagged: $value')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFeelingSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How are you feeling?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Feelings.options.map((f) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _feeling = '${f['emoji']} ${f['label']}');
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(f['emoji']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 4),
                        Text(f['label']!),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(hintText: 'Enter location', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              onSubmitted: (value) {
                setState(() => _location = value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackgroundSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Background', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...BackgroundGradients.gradients.keys.map((key) {
                  final colors = BackgroundGradients.getGradient(key);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _bgColor = key);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () {
                    setState(() => _bgColor = null);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('None')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePost() async {
    if (!_canPost()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write something or add a photo!')),
      );
      return;
    }

    try {
      final user = await UserService().getUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login first to create a post!')),
        );
        return;
      }

      setState(() => _isPosting = true);

      List<String> imageUrls = [];

      if (_selectedImages.isNotEmpty) {
        imageUrls = await FirestoreService.uploadImages(_selectedImages, user.userId);
      }

      final post = PostModel(
        id: PostModel.generateId(),
        authorId: user.userId,
        authorName: user.displayName,
        authorAvatarColor: user.avatarColor,
        text: _textController.text.trim(),
        bgColor: _bgColor,
        feeling: _feeling,
        location: _location,
        imageURLs: imageUrls,
        audience: _audience,
        createdAt: DateTime.now(),
        reactions: {},
        commentCount: 0,
      );

      await FirestoreService.createPost(post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }
}

class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: colorScheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}