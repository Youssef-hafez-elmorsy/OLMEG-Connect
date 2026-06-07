import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Uint8List? _selectedImageBytes;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _currentPhotoUrl = user.photoUrl;
      _loadProfileExtras(user.id);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileExtras(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!mounted) return;
    final data = doc.data();
    _bioController.text = data?['bio'] as String? ?? '';
    setState(() {
      _currentPhotoUrl = data?['photoUrl'] as String? ?? _currentPhotoUrl;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 420,
      maxHeight: 420,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() => _selectedImageBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F8FA);
    final surfaceColor = isDark ? const Color(0xFF182235) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final secColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final dividerColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(l10n.t('editProfile'), style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _saveProfile(context),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.t('save')),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ProfilePhotoCard(
              surfaceColor: surfaceColor,
              dividerColor: dividerColor,
              textColor: textColor,
              secColor: secColor,
              selectedImageBytes: _selectedImageBytes,
              photoUrl: _currentPhotoUrl,
              name: _nameController.text,
              onPickImage: _pickImage,
              onRemoveImage:
                  _currentPhotoUrl == null && _selectedImageBytes == null
                      ? null
                      : () => setState(() {
                            _selectedImageBytes = null;
                            _currentPhotoUrl = null;
                          }),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: dividerColor),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: textColor),
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(
                      label: l10n.t('fullName'),
                      icon: Icons.person_outline,
                      secColor: secColor,
                      dividerColor: dividerColor,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    enabled: false,
                    style: TextStyle(color: textColor),
                    decoration: _fieldDecoration(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      secColor: secColor,
                      dividerColor: dividerColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _bioController,
                    style: TextStyle(color: textColor),
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 160,
                    decoration: _fieldDecoration(
                      label: l10n.t('bio'),
                      icon: Icons.notes_outlined,
                      secColor: secColor,
                      dividerColor: dividerColor,
                    ).copyWith(hintText: l10n.t('profilePhotoHelp')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _isSaving ? null : () => _saveProfile(context),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? '${l10n.t('save')}...' : l10n.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required Color secColor,
    required Color dividerColor,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      labelStyle: TextStyle(color: secColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Future<void> _saveProfile(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? photoUrl = _currentPhotoUrl;
      if (_selectedImageBytes != null) {
        if (kIsWeb) {
          photoUrl =
              'data:image/jpeg;base64,${base64Encode(_selectedImageBytes!)}';
        } else {
          final ref = FirebaseStorage.instance.ref().child(
              'avatars/${authUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await ref.putData(
            _selectedImageBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          photoUrl = await ref.getDownloadURL();
        }
      }

      final name = _nameController.text.trim();
      final data = <String, dynamic>{
        'name': name,
        'bio': _bioController.text.trim(),
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (photoUrl == null) {
        data['photoUrl'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .set(data, SetOptions(merge: true));
      await authUser.updateDisplayName(name);
      if (photoUrl == null || !photoUrl.startsWith('data:image')) {
        await authUser.updatePhotoURL(photoUrl);
      }

      ref.invalidate(authStateProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('profileSaved'))),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _ProfilePhotoCard extends StatelessWidget {
  final Color surfaceColor;
  final Color dividerColor;
  final Color textColor;
  final Color secColor;
  final Uint8List? selectedImageBytes;
  final String? photoUrl;
  final String name;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  const _ProfilePhotoCard({
    required this.surfaceColor,
    required this.dividerColor,
    required this.textColor,
    required this.secColor,
    required this.selectedImageBytes,
    required this.photoUrl,
    required this.name,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              _ProfileImage(
                bytes: selectedImageBytes,
                url: photoUrl,
                name: name,
                size: 132,
              ),
              IconButton.filled(
                tooltip: 'Change photo',
                onPressed: onPickImage,
                icon: const Icon(Icons.camera_alt_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context).t('profilePhoto'),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).t('profilePhotoHelp'),
            textAlign: TextAlign.center,
            style: TextStyle(color: secColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(AppLocalizations.of(context).t('choosePhoto')),
              ),
              if (onRemoveImage != null)
                TextButton.icon(
                  onPressed: onRemoveImage,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(AppLocalizations.of(context).t('remove')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final Uint8List? bytes;
  final String? url;
  final String name;
  final double size;

  const _ProfileImage({
    required this.bytes,
    required this.url,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final image = _imageProvider();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? Center(
              child: Text(
                name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Image(image: image, fit: BoxFit.cover),
    );
  }

  ImageProvider? _imageProvider() {
    if (bytes != null) return MemoryImage(bytes!);
    final value = url?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(value.split(',').last));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(value);
  }
}
