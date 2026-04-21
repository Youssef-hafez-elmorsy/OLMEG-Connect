import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../presentation/providers/posts_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _descriptionCtrl = TextEditingController();
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imageExtension;
  bool _isLoading = false;

  bool get _hasImage => _imageFile != null || _imageBytes != null;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      if (kIsWeb) {
        // For web, read bytes directly from XFile
        final bytes = await picked.readAsBytes();
        
        // Get original extension from filename
        final ext = picked.name.split('.').last.toLowerCase();
        final validExt = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext) ? ext : 'jpg';
        
        setState(() {
          _imageFile = null;
          _imageBytes = bytes;
          _imageExtension = validExt;
        });
        
        debugPrint('[CreatePost] Web image picked: ${picked.name}, size: ${bytes.length}, ext: $validExt');
      } else {
        // For mobile, use File
        final ext = picked.path.split('.').last.toLowerCase();
        setState(() {
          _imageFile = File(picked.path);
          _imageBytes = null;
          _imageExtension = ext;
        });
      }
    }
  }

  Future<void> _createPost() async {
    if (!_hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (_descriptionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
      }
      return;
    }

    final error = await ref.read(postsNotifierProvider.notifier).createPost(
      authorId: user.id,
      authorName: user.name,
      authorPhotoUrl: user.photoUrl,
      description: _descriptionCtrl.text.trim(),
      imageBytes: _imageBytes,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb && _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : const Icon(Icons.image, size: 48),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap to add image',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write a description...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Post'),
            ),
          ],
        ),
      ),
    );
  }
}