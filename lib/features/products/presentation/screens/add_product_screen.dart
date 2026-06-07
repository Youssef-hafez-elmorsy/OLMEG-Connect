import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/services/ai_marketplace_service.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/navigation_utils.dart';
import 'package:olmeg_connect/core/widgets/quantity_selector.dart';
import 'package:olmeg_connect/features/auth/domain/entities/merchant_verification_entity.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/products/data/services/product_moderation_service.dart';
import 'package:olmeg_connect/features/products/domain/entities/category_entity.dart';
import 'package:olmeg_connect/features/products/presentation/providers/category_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _ListingQualityChecklist extends StatelessWidget {
  final int score;
  final List<_ListingQualityItem> items;

  const _ListingQualityChecklist({
    required this.score,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.t('listingQuality'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('$score/${items.length}'),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      item.isComplete
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: item.isComplete
                          ? colorScheme.primary
                          : colorScheme.outline,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.label)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListingQualityItem {
  final String label;
  final bool isComplete;

  const _ListingQualityItem(this.label, this.isComplete);
}

class _SellerAiHintsCard extends StatelessWidget {
  final AiSellerHints? hints;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _SellerAiHintsCard({
    required this.hints,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      ...?hints?.titleSuggestions,
      ...?hints?.descriptionSuggestions,
      ...?hints?.pricingSignals,
      ...?hints?.trustSignals,
    ].take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI seller hints',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: isLoading ? null : onRefresh,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.tips_and_updates_outlined),
                  label: const Text('Improve'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                'Get title, description, pricing, and trust suggestions before publishing.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              )
            else
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  int _quantity = 1;

  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imageExtension;
  bool _isLoading = false;
  List<Uint8List> _imageBytesList = [];
  List<File> _imageFilesList = [];
  bool _saveAsDraft = false;
  bool _scheduleTomorrow = false;
  bool _loadingSellerHints = false;
  AiSellerHints? _sellerHints;

  bool get _hasImage =>
      _imageFile != null ||
      _imageBytes != null ||
      _imageBytesList.isNotEmpty ||
      _imageFilesList.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryNotifierProvider.notifier).initializeCategories();
    });
  }

  Future<void> _forceInitialize() async {
    await ref.read(categoryNotifierProvider.notifier).initializeCategories();
    ref.invalidate(categoriesStreamProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).t('categoriesInitialized')),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(CategoryEntity? category) {
    ref.read(selectedCategoryProvider.notifier).select(category);
    ref.read(selectedSubcategoryProvider.notifier).select(null);
  }

  void _onSubcategoryChanged(SubcategoryEntity? subcategory) {
    ref.read(selectedSubcategoryProvider.notifier).select(subcategory);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      if (kIsWeb) {
        setState(() {
          _imageBytesList = [];
        });
        for (final img in picked) {
          final bytes = await img.readAsBytes();
          _imageBytesList.add(bytes);
        }
        if (mounted) {
          setState(() {
            _imageFilesList = [];
          });
        }
      } else {
        setState(() {
          _imageFilesList = [];
          for (final img in picked) {
            _imageFilesList.add(File(img.path));
          }
          _imageBytesList = [];
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb && _imageBytesList.isNotEmpty) {
        _imageBytesList.removeAt(index);
      } else if (_imageFilesList.isNotEmpty) {
        _imageFilesList.removeAt(index);
      }
    });
  }

  Future<String?> _uploadImages() async {
    try {
      final urls = <String>[];

      if (kIsWeb && _imageBytesList.isNotEmpty) {
        for (int i = 0; i < _imageBytesList.length; i++) {
          final base64String = base64Encode(_imageBytesList[i]);
          final ext = 'jpg';
          urls.add('data:image/$ext;base64,$base64String');
        }
      } else if (_imageFilesList.isNotEmpty) {
        for (int i = 0; i < _imageFilesList.length; i++) {
          final ref = FirebaseStorage.instance.ref();
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final imageRef = ref.child('products/$fileName');
          final task = imageRef.putFile(_imageFilesList[i]);
          final url = await task.then((s) => s.ref.getDownloadURL());
          urls.add(url);
        }
      } else if (_imageBytes != null) {
        final base64String = base64Encode(_imageBytes!);
        return 'data:image/$_imageExtension;base64,$base64String';
      } else if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}.$_imageExtension';
        final imageRef = ref.child('products/$fileName');
        final task = imageRef.putFile(_imageFile!);
        return await task.then((s) => s.ref.getDownloadURL());
      }

      return urls.isNotEmpty ? urls.join('|||') : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    final selectedCategory = ref.read(selectedCategoryProvider);
    final selectedSubcategory = ref.read(selectedSubcategoryProvider);

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('categoryRequired'))),
      );
      return;
    }

    if (selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('subcategoryRequired'))),
      );
      return;
    }

    if (!_hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('imageRequired'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrls = await _uploadImages();
      final user = ref.read(authStateProvider).value;

      if (user == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('signInFirst'))),
          );
        }
        return;
      }

      List<String> imagesList = [];
      if (imageUrls != null && imageUrls.contains('|||')) {
        imagesList = imageUrls.split('|||');
      } else if (imageUrls != null) {
        imagesList = [imageUrls];
      }

      final productRef =
          FirebaseFirestore.instance.collection('products').doc();
      final productData = {
        'titleLower': _titleCtrl.text.trim().toLowerCase(),
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'stock': _quantity,
        'stockQuantity': _quantity,
        'status': _saveAsDraft
            ? 'draft'
            : _scheduleTomorrow
                ? 'scheduled'
                : 'active',
        'publishStatus': _saveAsDraft
            ? 'draft'
            : _scheduleTomorrow
                ? 'scheduled'
                : 'published',
        'scheduledPublishAt': _scheduleTomorrow
            ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 1)))
            : null,
        'promotionStatus': 'none',
        'discountCampaignId': null,
        'ratingAverage': 0,
        'ratingCount': 0,
        'variants': const [],
        'returnPolicy': 'Contact seller for return details',
        'deliveryEstimate': selectedCategory.name.toLowerCase().contains('hand')
            ? 'Delivery available for handmade products'
            : '',
        'category': selectedCategory.name,
        'categoryId': selectedCategory.id,
        'categoryName': selectedCategory.name,
        'subcategory': selectedSubcategory.name,
        'subCategoryId': selectedSubcategory.id,
        'subCategoryName': selectedSubcategory.name,
        'imageUrl': imagesList.isNotEmpty ? imagesList.first : '',
        'images': imagesList,
        'sellerId': user.id,
        'sellerName': user.name,
        'sellerPhotoUrl': user.photoUrl,
        'sellerMerchantVerificationStatus': merchantVerificationStatusToString(
          user.merchantVerificationStatus,
        ),
        'listingQualityScore': _listingQualityScore,
        'listingQualityChecklist': [
          for (final item in _listingQualityChecklist)
            {'label': item.label, 'isComplete': item.isComplete},
        ],
        'deliveryEligible':
            selectedCategory.name.toLowerCase().contains('hand') &&
                user.isApprovedMerchant,
        'location': _locationCtrl.text.trim(),
        'city': _locationCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final moderation = await ProductAiModerationService().review(
        productId: productRef.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        category: selectedCategory.name,
        subcategory: selectedSubcategory.name,
        location: _locationCtrl.text.trim(),
        imageUrl: imagesList.isNotEmpty ? imagesList.first : null,
      );

      final reviewedProductData = {
        ...productData,
        'id': productRef.id,
        'moderationStatus': _saveAsDraft
            ? 'draft'
            : moderation.approved
                ? 'approved'
                : 'pending_admin',
        'moderationDecision': _saveAsDraft
            ? 'seller_draft'
            : moderation.approved
                ? 'accepted'
                : 'needs_admin_review',
        'moderationReason': moderation.reasons.join('\n'),
        'moderationConfidence': moderation.confidence,
        'aiRiskScore': moderation.riskScore,
        'aiRiskLevel': moderation.riskLevel,
        'aiSuggestedAction': moderation.suggestedAction,
        'aiReasons': moderation.reasons,
        'aiSignals': moderation.signals,
        'aiSellerHints': moderation.sellerHints,
        'aiProvider': moderation.provider,
        'aiModel': moderation.model,
        'moderatedAt': FieldValue.serverTimestamp(),
      };

      if (_saveAsDraft) {
        await productRef.set(reviewedProductData);
      } else if (moderation.approved) {
        await productRef.set(reviewedProductData);
        await _createUserNotification(
          userId: user.id,
          title: 'Product approved',
          message: '${_titleCtrl.text.trim()} is now published.',
          relatedId: productRef.id,
        );
      } else {
        await FirebaseFirestore.instance
            .collection('product_submissions')
            .doc(productRef.id)
            .set(reviewedProductData);
        await _createUserNotification(
          userId: user.id,
          title: 'Product sent to admin review',
          message:
              '${_titleCtrl.text.trim()} needs admin review before publication.',
          relatedId: productRef.id,
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              moderation.approved
                  ? (_scheduleTomorrow
                      ? l10n.t('productApprovedScheduled')
                      : l10n.t('productApprovedListed'))
                  : _saveAsDraft
                      ? l10n.t('productSavedDraft')
                      : l10n.t('productSentReview'),
            ),
          ),
        );
        closeOrGo(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadSellerHints() async {
    final selectedCategory = ref.read(selectedCategoryProvider);
    final selectedSubcategory = ref.read(selectedSubcategoryProvider);
    final price = double.tryParse(_priceCtrl.text.trim());
    if (_titleCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty ||
        price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a title, description, and price first.'),
        ),
      );
      return;
    }

    setState(() => _loadingSellerHints = true);
    final hints = await AiMarketplaceService().sellerHints(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: price,
      category: selectedCategory?.name,
      subcategory: selectedSubcategory?.name,
      location: _locationCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _sellerHints = hints;
      _loadingSellerHints = false;
    });
  }

  Future<void> _createUserNotification({
    required String userId,
    required String title,
    required String message,
    required String relatedId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'body': message,
      'type': 'product_moderation',
      'relatedId': relatedId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : const Color(0xFFF5F5F7);
    final cardColor = isDark ? AppColors.card : const Color(0xFFFFFFFF);
    final textColor = isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
    final secColor = isDark ? AppColors.textSecondary : const Color(0xFF64748B);
    final dividerColor = isDark ? AppColors.divider : const Color(0xFFE2E8F0);

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final l10n = AppLocalizations.of(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSubcategory = ref.watch(selectedSubcategoryProvider);

    final subcategoriesAsync = selectedCategory != null
        ? ref.watch(subcategoriesStreamProvider(selectedCategory.id))
        : const AsyncValue<List<SubcategoryEntity>>.data([]);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(l10n.t('addProduct'), style: TextStyle(color: textColor)),
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => closeOrGo(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: _hasImage ? 220 : 200,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dividerColor),
                  ),
                  child: _hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              kIsWeb && _imageBytesList.isNotEmpty
                                  ? GridView.builder(
                                      padding: const EdgeInsets.all(4),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 4,
                                        mainAxisSpacing: 4,
                                      ),
                                      itemCount: _imageBytesList.length,
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.memory(
                                                  _imageBytesList[index],
                                                  fit: BoxFit.cover),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _removeImage(index),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.close,
                                                      color: Colors.white,
                                                      size: 16),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                  : _imageFilesList.isNotEmpty
                                      ? GridView.builder(
                                          padding: const EdgeInsets.all(4),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 4,
                                            mainAxisSpacing: 4,
                                          ),
                                          itemCount: _imageFilesList.length,
                                          itemBuilder: (context, index) {
                                            return Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.file(
                                                      _imageFilesList[index],
                                                      fit: BoxFit.cover),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        _removeImage(index),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        )
                                      : kIsWeb && _imageBytes != null
                                          ? Image.memory(_imageBytes!,
                                              fit: BoxFit.cover)
                                          : _imageFile != null
                                              ? Image.file(_imageFile!,
                                                  fit: BoxFit.cover)
                                              : const Icon(Icons.image,
                                                  size: 48),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: bgColor.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add,
                                      color: textColor, size: 20),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 48, color: secColor),
                            const SizedBox(height: 8),
                            Text(l10n.t('tapToAddImages'),
                                style: TextStyle(color: secColor)),
                            Text('(${l10n.t('selectMultiple')})',
                                style:
                                    TextStyle(color: secColor, fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleCtrl,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(l10n.t('productTitle'),
                    Icons.title, secColor, cardColor, dividerColor),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.t('titleRequired') : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(l10n.t('description'),
                    Icons.description, secColor, cardColor, dividerColor,
                    alignLabelWithHint: true),
                onChanged: (_) => setState(() {}),
                validator: (v) => v == null || v.isEmpty
                    ? l10n.t('descriptionRequired')
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(l10n.t('price'),
                    Icons.attach_money, secColor, cardColor, dividerColor),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.t('priceRequired');
                  if (double.tryParse(v) == null) return l10n.t('validNumber');
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(
                        l10n.t('cityOrArea'),
                        Icons.location_on_outlined,
                        secColor,
                        cardColor,
                        dividerColor)
                    .copyWith(hintText: l10n.t('locationHint')),
                onChanged: (_) => setState(() {}),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.t('locationRequired')
                    : null,
              ),
              const SizedBox(height: 16),

              QuantitySelector(
                label: l10n.t('quantity'),
                quantity: _quantity,
                maxQuantity: 99,
                onChanged: (q) => setState(() => _quantity = q),
              ),
              const SizedBox(height: 24),

              Text('${l10n.t('category')} *',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              categoriesAsync.when(
                loading: () => _buildLoadingDropdown(secColor, cardColor),
                error: (e, _) => _buildErrorDropdown(
                    'Error loading categories: $e', secColor, cardColor),
                data: (categories) => categories.isEmpty
                    ? _buildEmptyCategories(secColor, cardColor)
                    : _buildCategoryDropdown(
                        categories,
                        selectedCategory,
                        secColor,
                        cardColor,
                        dividerColor,
                      ),
              ),
              // DEBUG: Force init button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _forceInitialize,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(
                    AppLocalizations.of(context).t('initializeCategories'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('${l10n.t('subcategory')} *',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildSubcategoryDropdown(
                selectedCategory,
                selectedSubcategory,
                subcategoriesAsync,
                secColor,
                cardColor,
                dividerColor,
              ),
              const SizedBox(height: 24),

              _ListingQualityChecklist(
                score: _listingQualityScore,
                items: _listingQualityChecklist,
              ),
              const SizedBox(height: 24),
              _SellerAiHintsCard(
                hints: _sellerHints,
                isLoading: _loadingSellerHints,
                onRefresh: _loadSellerHints,
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('saveAsDraft')),
                subtitle: Text(l10n.t('draftSubtitle')),
                value: _saveAsDraft,
                onChanged: (value) {
                  setState(() {
                    _saveAsDraft = value;
                    if (value) _scheduleTomorrow = false;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('scheduleTomorrow')),
                subtitle: Text(l10n.t('scheduleSubtitle')),
                value: _scheduleTomorrow,
                onChanged: _saveAsDraft
                    ? null
                    : (value) => setState(() => _scheduleTomorrow = value),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: bgColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.t('listProduct')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get _listingQualityScore {
    return _listingQualityChecklist.where((item) => item.isComplete).length;
  }

  List<_ListingQualityItem> get _listingQualityChecklist {
    return [
      _ListingQualityItem(
        AppLocalizations.of(context).t('clearTitle'),
        _titleCtrl.text.trim().length >= 8,
      ),
      _ListingQualityItem(
        AppLocalizations.of(context).t('helpfulDescription'),
        _descCtrl.text.trim().length >= 40,
      ),
      _ListingQualityItem(AppLocalizations.of(context).t('validPrice'),
          double.tryParse(_priceCtrl.text) != null),
      _ListingQualityItem(
          AppLocalizations.of(context).t('atLeastOneImage'), _hasImage),
      _ListingQualityItem(
          AppLocalizations.of(context).t('stockQuantitySet'), _quantity > 0),
      _ListingQualityItem(AppLocalizations.of(context).t('locationAdded'),
          _locationCtrl.text.trim().isNotEmpty),
    ];
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    Color secColor,
    Color cardColor,
    Color dividerColor, {
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: secColor),
      prefixIcon: Icon(icon, color: secColor),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildLoadingDropdown(Color secColor, Color cardColor) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: secColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text(l10n.t('loadingCategories'), style: TextStyle(color: secColor)),
        ],
      ),
    );
  }

  Widget _buildErrorDropdown(String message, Color secColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildEmptyCategories(Color secColor, Color cardColor) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: secColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.category_outlined, color: secColor, size: 32),
          const SizedBox(height: 8),
          Text(l10n.t('noCategoriesFound'), style: TextStyle(color: secColor)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _forceInitialize,
            child: Text(l10n.t('initializeCategories')),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(
    List<CategoryEntity> categories,
    CategoryEntity? selectedCategory,
    Color secColor,
    Color cardColor,
    Color dividerColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CategoryEntity>(
          isExpanded: true,
          value: selectedCategory,
          hint: Text(AppLocalizations.of(context).t('selectCategory'),
              style: TextStyle(color: secColor)),
          icon: const Icon(Icons.arrow_drop_down),
          dropdownColor: cardColor,
          items: (() {
            // Remove duplicates by name
            final seen = <String>{};
            final unique = <CategoryEntity>[];
            for (final c in categories) {
              final n = c.name.toLowerCase().trim();
              if (!seen.contains(n)) {
                seen.add(n);
                unique.add(c);
              }
            }
            unique.sort((a, b) => a.name.compareTo(b.name));
            return unique;
          })()
              .map((cat) {
            return DropdownMenuItem<CategoryEntity>(
              value: cat,
              child: Text(cat.name,
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black)),
            );
          }).toList(),
          onChanged: (category) {
            _onCategoryChanged(category);
          },
        ),
      ),
    );
  }

  Widget _buildSubcategoryDropdown(
    CategoryEntity? selectedCategory,
    SubcategoryEntity? selectedSubcategory,
    AsyncValue<List<SubcategoryEntity>> subcategoriesAsync,
    Color secColor,
    Color cardColor,
    Color dividerColor,
  ) {
    if (selectedCategory == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline,
                color: secColor.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).t('selectCategoryFirst'),
                style: TextStyle(color: secColor.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      );
    }

    return subcategoriesAsync.when(
      loading: () => _buildLoadingDropdown(secColor, cardColor),
      error: (e, _) => _buildErrorDropdown(
          'Error loading subcategories', secColor, cardColor),
      data: (subcategories) {
        if (subcategories.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dividerColor),
            ),
            child: Text(
              AppLocalizations.of(context).t('noSubcategories'),
              style: TextStyle(color: secColor),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SubcategoryEntity>(
              isExpanded: true,
              value: selectedSubcategory,
              hint: Text(AppLocalizations.of(context).t('selectSubcategory'),
                  style: TextStyle(color: secColor)),
              icon: const Icon(Icons.arrow_drop_down),
              dropdownColor: cardColor,
              items: subcategories.map((sub) {
                return DropdownMenuItem<SubcategoryEntity>(
                  value: sub,
                  child: Text(sub.name,
                      style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)),
                );
              }).toList(),
              onChanged: (subcategory) {
                _onSubcategoryChanged(subcategory);
              },
            ),
          ),
        );
      },
    );
  }
}
