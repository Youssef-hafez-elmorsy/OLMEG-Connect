import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/utils/navigation_utils.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';
import 'package:olmeg_connect/features/posts/services/firestore_service.dart';
import 'package:olmeg_connect/features/posts/services/user_service.dart';
import 'package:olmeg_connect/features/posts/widgets/avatar_widget.dart';
import 'package:olmeg_connect/features/posts/widgets/image_preview_grid.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  String _postType = 'made';

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  List<XFile> _selectedImages = [];
  List<double> _uploadProgress = [];
  final String _audience = 'public';
  bool _isPosting = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => closeOrGo(context),
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
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colorScheme.primary))
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
                  _buildPostTypeToggle(context),
                  _buildTitleField(context),
                  _buildCategoryField(context),
                  _buildDescriptionField(context),
                  if (_postType == 'made') _buildPriceField(context),
                  if (_postType == 'wanted') _buildBudgetField(context),
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
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colorScheme.onPrimary))
                      : const Icon(Icons.send, size: 24),
                  label: Text(
                    _isPosting ? 'Publishing...' : 'Publish Post',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor:
                        colorScheme.surfaceContainerHighest,
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
              AvatarWidget(
                  imageUrl: user?.profileImageUrl,
                  name: user?.displayName,
                  avatarColor: user?.avatarColor ?? '0xFF9E9E9E',
                  sizeType: AvatarSizeType.medium),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? 'User',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(_postType == 'made' ? 'Selling' : 'Looking for',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostTypeToggle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _postType = 'made'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _postType == 'made'
                        ? colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'I Made Products',
                      style: TextStyle(
                        color: _postType == 'made'
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _postType = 'wanted'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _postType == 'wanted'
                        ? colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'I Want Products',
                      style: TextStyle(
                        color: _postType == 'wanted'
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _titleController,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: _postType == 'made'
              ? 'Title (e.g., Beautiful Handmade Vase)'
              : 'What are you looking for?',
          hintText: _postType == 'made'
              ? 'Enter product title'
              : 'Describe what you need',
          prefixIcon: Icon(
            _postType == 'made' ? Icons.sell : Icons.search,
            color: colorScheme.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildCategoryField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final categories = [
      'New',
      'Used',
      'Handicraft',
      'Jewelry',
      'Electronics',
      'Clothing',
      'Home',
      'Sports',
      'Books',
      'Toys'
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue:
            _categoryController.text.isEmpty ? null : _categoryController.text,
        decoration: InputDecoration(
          labelText: l10n.t('category'),
          prefixIcon: Icon(
            Icons.category,
            color: colorScheme.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        items: categories
            .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(l10n.categoryLabel(cat)),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _categoryController.text = value ?? '';
          });
        },
      ),
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = _descriptionController.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _descriptionController,
            maxLines: null,
            minLines: 4,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Describe your product or what you need...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            '${text.length}/500',
            style: TextStyle(
              color: text.length > 450
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Price (optional)',
          hintText: 'Enter price',
          prefixIcon: Icon(
            Icons.attach_money,
            color: colorScheme.primary,
          ),
          suffixText: 'USD',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildBudgetField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Budget (optional)',
          hintText: 'Enter your budget',
          prefixIcon: Icon(
            Icons.account_balance_wallet,
            color: colorScheme.primary,
          ),
          suffixText: 'USD',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (_) => setState(() {}),
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
            _AttachmentButton(
                icon: Icons.photo, label: 'Photo', onTap: _pickImages),
          ],
        ),
      ),
    );
  }

  bool _canPost() {
    return _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _selectedImages.isNotEmpty;
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

  Future<void> _handlePost() async {
    if (!_canPost()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in the title or add a photo!')),
      );
      return;
    }

    try {
      final user = await UserService().getUser();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please login first to create a post!')),
          );
        }
        return;
      }

      setState(() => _isPosting = true);

      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls =
            await FirestoreService.uploadImages(_selectedImages, user.userId);
      }

      final price = _priceController.text.trim().isNotEmpty
          ? double.tryParse(_priceController.text.trim())
          : null;

      final post = PostModel(
        id: PostModel.generateId(),
        authorId: user.userId,
        authorName: user.displayName,
        authorProfileImageUrl: user.profileImageUrl,
        authorAvatarColor: user.avatarColor,
        text: _descriptionController.text.trim(),
        postType: _postType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : null,
        price: _postType == 'made' ? price : null,
        budget: _postType == 'wanted' ? price : null,
        imageURLs: imageUrls,
        audience: _audience,
        createdAt: DateTime.now(),
        reactions: {},
        commentCount: 0,
      );

      await FirestoreService.createPost(post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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

  const _AttachmentButton(
      {required this.icon, required this.label, required this.onTap});

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
