import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:olmeg_connect/features/products/domain/entities/category_entity.dart';

class CategoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _categoriesRef => _firestore.collection('categories');
  static CollectionReference get _subcategoriesRef => _firestore.collection('subcategories');

  static Stream<List<CategoryEntity>> getCategoriesStream() {
    debugPrint('[CategoryService] Creating categories stream');
    return _categoriesRef.orderBy('name').snapshots().map(
      (snapshot) {
        final categories = snapshot.docs.map((doc) => CategoryEntity.fromFirestore(doc.id, doc.data() as Map<String, dynamic>)).toList();
        debugPrint('[CategoryService] Categories stream emitted: ${categories.length} categories');
        return categories;
      },
    );
  }

  static Future<List<CategoryEntity>> getCategories() async {
    final snapshot = await _categoriesRef.orderBy('name').get();
    return snapshot.docs.map((doc) => CategoryEntity.fromFirestore(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  static Stream<List<SubcategoryEntity>> getSubcategoriesStream(String categoryId) {
    debugPrint('[CategoryService] Creating subcategories stream for categoryId: $categoryId');
    return _subcategoriesRef
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => SubcategoryEntity.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => a.name.compareTo(b.name));
          debugPrint('[CategoryService] Subcategories stream emitted: ${list.length} subcategories');
          return list;
        });
  }

  static Future<List<SubcategoryEntity>> getSubcategories(String categoryId) async {
    final snapshot = await _subcategoriesRef
        .where('categoryId', isEqualTo: categoryId)
        .get();
    final list = snapshot.docs
        .map((doc) => SubcategoryEntity.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  static Future<void> createCategory(String name) async {
    await _categoriesRef.add({'name': name});
  }

  static Future<void> createSubcategory(String name, String categoryId) async {
    await _subcategoriesRef.add({
      'name': name,
      'categoryId': categoryId,
    });
  }

  static Future<void> initializeDefaultCategories() async {
    debugPrint('[CategoryService] Initializing default categories...');
    final existing = await _categoriesRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      debugPrint('[CategoryService] Categories already exist, skipping initialization');
      return;
    }

    debugPrint('[CategoryService] Creating default categories...');
    final defaultCategories = [
      {'name': 'New'},
      {'name': 'Used'},
      {'name': 'Handicraft'},
      {'name': 'Jewelry'},
    ];

    for (final cat in defaultCategories) {
      final docRef = await _categoriesRef.add(cat);
      final categoryId = docRef.id;

      final defaultSubcategories = _getSubcategoriesForCategory(cat['name'] as String);
      debugPrint('[CategoryService] Creating ${defaultSubcategories.length} subcategories for $categoryId');
      
      for (final subcat in defaultSubcategories) {
        await _subcategoriesRef.add({
          'name': subcat,
          'categoryId': categoryId,
        });
      }
    }
    debugPrint('[CategoryService] Default categories initialized');
  }

  static List<String> _getSubcategoriesForCategory(String categoryName) {
    switch (categoryName) {
      case 'New':
        return ['Electronics', 'Clothing', 'Furniture', 'Sports', 'Books', 'Toys', 'Cars', 'Bikes', 'Jewelry', 'Home & Garden', 'Fashion', 'Beauty', 'Other'];
      case 'Used':
        return ['Cars', 'Bikes', 'Electronics', 'Clothing', 'Furniture', 'Sports', 'Books', 'Toys', 'Jewelry', 'Home & Garden', 'Fashion', 'Beauty', 'Other'];
      case 'Handicraft':
        return ['Pottery', 'Textiles', 'Woodwork', 'Jewelry', 'Paintings', 'Candles', 'Knitting', 'Embroidery', 'Other'];
      case 'Jewelry':
        return ['Rings', 'Necklaces', 'Bracelets', 'Earrings', 'Watches', 'Pendants', 'Anklets', 'Other'];
      default:
        return ['Other'];
    }
  }
}