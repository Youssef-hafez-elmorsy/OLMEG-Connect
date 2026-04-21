import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/product_provider.dart';

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
  String _selectedCategory = AppConstants.categoryNew;
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageFile = null;
          _imageBytes = bytes;
          _imagePath = picked.path;
        });
      } else {
        setState(() {
          _imageFile = File(picked.path);
          _imageBytes = null;
          _imagePath = picked.path;
        });
      }
    }
  }

  bool get _hasImage => _imageFile != null || _imageBytes != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product image'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    setState(() => _isLoading = true);
    
    File? fileToUpload = _imageFile;
    
    final error = await ref.read(addProductNotifierProvider.notifier).addProduct(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      category: _selectedCategory,
      imageFile: fileToUpload,
      imageBytes: _imageBytes,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.errorColor));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product listed successfully!'), backgroundColor: AppTheme.successColor));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List a Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb && _imageBytes != null
                              ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                              : _imageFile != null
                                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                                  : const Icon(Icons.image, size: 48),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                            const Gap(8),
                            Text('Tap to add product image', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                ),
              ),
              const Gap(20),
              AppTextField(controller: _titleCtrl, label: 'Product Title', prefixIcon: Icons.title, validator: (v) => Validators.required(v, fieldName: 'Title')),
              const Gap(16),
              AppTextField(controller: _descCtrl, label: 'Description', prefixIcon: Icons.description_outlined, maxLines: 4, validator: (v) => Validators.required(v, fieldName: 'Description')),
              const Gap(16),
              AppTextField(controller: _priceCtrl, label: 'Price', prefixIcon: Icons.attach_money, keyboardType: TextInputType.number, validator: Validators.price),
              const Gap(16),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const Gap(8),
              Wrap(
                spacing: 8,
                children: AppConstants.categories.map((cat) {
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Chip(
                      label: Text(cat),
                      backgroundColor: selected ? AppTheme.primaryColor : Colors.grey.shade200,
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                    ),
                  );
                }).toList(),
              ),
              const Gap(28),
              AppButton(label: 'List Product', onPressed: _submit, isLoading: _isLoading, icon: Icons.upload),
            ],
          ),
        ),
      ),
    );
  }
}