import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/widgets/quantity_selector.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/products/domain/entities/category_entity.dart';
import 'package:olmeg_connect/features/products/presentation/providers/category_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  int _quantity = 1;
  
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imageExtension;
  bool _isLoading = false;
  List<Uint8List> _imageBytesList = [];
  List<File> _imageFilesList = [];

  bool get _hasImage => _imageFile != null || _imageBytes != null || _imageBytesList.isNotEmpty || _imageFilesList.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[AddProduct] initState - initializing categories');
      ref.read(categoryNotifierProvider.notifier).initializeCategories();
    });
  }

  Future<void> _forceInitialize() async {
    print('[AddProduct] Force initializing categories...');
    await ref.read(categoryNotifierProvider.notifier).initializeCategories();
    ref.invalidate(categoriesStreamProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categories initialized!')),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(CategoryEntity? category) {
    print('[AddProduct] Category changed to: ${category?.name} (${category?.id})');
    ref.read(selectedCategoryProvider.notifier).state = category;
    ref.read(selectedSubcategoryProvider.notifier).state = null;
    print('[AddProduct] Subcategory reset to null');
  }

  void _onSubcategoryChanged(SubcategoryEntity? subcategory) {
    print('[AddProduct] Subcategory changed to: ${subcategory?.name} (${subcategory?.id})');
    ref.read(selectedSubcategoryProvider.notifier).state = subcategory;
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
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$_imageExtension';
        final imageRef = ref.child('products/$fileName');
        final task = imageRef.putFile(_imageFile!);
        return await task.then((s) => s.ref.getDownloadURL());
      }
      
      return urls.isNotEmpty ? urls.join('|||') : null;
    } catch (e) {
      print('Error uploading images: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final selectedCategory = ref.read(selectedCategoryProvider);
    final selectedSubcategory = ref.read(selectedSubcategoryProvider);
    
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    
    if (selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subcategory')),
      );
      return;
    }
    
    if (!_hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product image')),
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
            const SnackBar(content: Text('Please sign in first')),
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

      final productData = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'stock': _quantity,
        'categoryId': selectedCategory.id,
        'categoryName': selectedCategory.name,
        'subCategoryId': selectedSubcategory.id,
        'subCategoryName': selectedSubcategory.name,
        'imageUrl': imagesList.isNotEmpty ? imagesList.first : '',
        'images': imagesList,
        'sellerId': user.id,
        'sellerName': user.name,
        'sellerPhotoUrl': user.photoUrl,
        'location': '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('products').add(productData);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product listed successfully!')),
        );
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : const Color(0xFFF5F5F7);
    final surfaceColor = isDark ? AppColors.surface : Colors.white;
    final cardColor = isDark ? AppColors.card : const Color(0xFFFFFFFF);
    final textColor = isDark ? AppColors.textPrimary : const Color(0xFF1E293B);
    final secColor = isDark ? AppColors.textSecondary : const Color(0xFF64748B);
    final dividerColor = isDark ? AppColors.divider : const Color(0xFFE2E8F0);

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSubcategory = ref.watch(selectedSubcategoryProvider);
    
    final subcategoriesAsync = selectedCategory != null 
        ? ref.watch(subcategoriesStreamProvider(selectedCategory.id))
        : const AsyncValue<List<SubcategoryEntity>>.data([]);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('List a Product', style: TextStyle(color: textColor)),
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => context.pop(),
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
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 4,
                                        mainAxisSpacing: 4,
                                      ),
                                      itemCount: _imageBytesList.length,
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.memory(_imageBytesList[index], fit: BoxFit.cover),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeImage(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
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
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 4,
                                            mainAxisSpacing: 4,
                                          ),
                                          itemCount: _imageFilesList.length,
                                          itemBuilder: (context, index) {
                                            return Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.file(_imageFilesList[index], fit: BoxFit.cover),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: GestureDetector(
                                                    onTap: () => _removeImage(index),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        )
                                      : kIsWeb && _imageBytes != null
                                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                                          : _imageFile != null
                                              ? Image.file(_imageFile!, fit: BoxFit.cover)
                                              : const Icon(Icons.image, size: 48),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: bgColor.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add, color: textColor, size: 20),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: secColor),
                            const SizedBox(height: 8),
                            Text('Tap to add images', style: TextStyle(color: secColor)),
                            Text('(Select multiple)', style: TextStyle(color: secColor, fontSize: 12)),
                          ],
                        ),
),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleCtrl,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration('Product Title', Icons.title, secColor, cardColor, dividerColor),
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration('Description', Icons.description, secColor, cardColor, dividerColor, alignLabelWithHint: true),
                validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration('Price', Icons.attach_money, secColor, cardColor, dividerColor),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Price is required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              QuantitySelector(
                label: 'Quantity',
                quantity: _quantity,
                maxQuantity: 99,
                onChanged: (q) => setState(() => _quantity = q),
              ),
              const SizedBox(height: 24),

              const Text('Category *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              categoriesAsync.when(
                loading: () => _buildLoadingDropdown(secColor, cardColor),
                error: (e, _) => _buildErrorDropdown('Error loading categories: $e', secColor, cardColor),
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
                  label: const Text('Init Categories', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Subcategory *', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('List Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: secColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text('Loading categories...', style: TextStyle(color: secColor)),
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
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildEmptyCategories(Color secColor, Color cardColor) {
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
          Text('No categories found', style: TextStyle(color: secColor)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _forceInitialize,
            child: const Text('Initialize Categories'),
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
          hint: Text('Select Category', style: TextStyle(color: secColor)),
          icon: const Icon(Icons.arrow_drop_down),
          dropdownColor: cardColor,
          items: categories.map((cat) {
            return DropdownMenuItem<CategoryEntity>(
              value: cat,
              child: Text(cat.name, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
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
            Icon(Icons.lock_outline, color: secColor.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select Category First',
                style: TextStyle(color: secColor.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      );
    }

    return subcategoriesAsync.when(
      loading: () => _buildLoadingDropdown(secColor, cardColor),
      error: (e, _) => _buildErrorDropdown('Error loading subcategories', secColor, cardColor),
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
              'No subcategories available',
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
              hint: Text('Select Subcategory', style: TextStyle(color: secColor)),
              icon: const Icon(Icons.arrow_drop_down),
              dropdownColor: cardColor,
              items: subcategories.map((sub) {
                return DropdownMenuItem<SubcategoryEntity>(
                  value: sub,
                  child: Text(sub.name, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
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