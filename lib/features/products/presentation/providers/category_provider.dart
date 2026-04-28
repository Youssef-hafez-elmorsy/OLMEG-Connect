import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/products/data/services/category_service.dart';
import 'package:olmeg_connect/features/products/domain/entities/category_entity.dart';

final categoriesStreamProvider = StreamProvider<List<CategoryEntity>>((ref) {
  final stream = CategoryService.getCategoriesStream();
  return stream.map((categories) {
    debugPrint('[CategoriesProvider] Categories: ${categories.length}');
    return categories;
  });
});

final subcategoriesStreamProvider = StreamProvider.family<List<SubcategoryEntity>, String>((ref, categoryId) {
  if (categoryId.isEmpty) {
    return Stream.value([]);
  }
  final stream = CategoryService.getSubcategoriesStream(categoryId);
  return stream.map((subcategories) {
    debugPrint('[SubcategoriesProvider] Subcategories: ${subcategories.length}');
    return subcategories;
  });
});

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, CategoryEntity?>(() {
  return SelectedCategoryNotifier();
});

class SelectedCategoryNotifier extends Notifier<CategoryEntity?> {
  @override
  CategoryEntity? build() => null;

  void select(CategoryEntity? category) {
    state = category;
  }

  void clear() {
    state = null;
  }
}

final selectedSubcategoryProvider = NotifierProvider<SelectedSubcategoryNotifier, SubcategoryEntity?>(() {
  return SelectedSubcategoryNotifier();
});

class SelectedSubcategoryNotifier extends Notifier<SubcategoryEntity?> {
  @override
  SubcategoryEntity? build() => null;

  void select(SubcategoryEntity? subcategory) {
    state = subcategory;
  }

  void clear() {
    state = null;
  }
}

class CategoryNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> initializeCategories() async {
    state = const AsyncValue.loading();
    try {
      await CategoryService.initializeDefaultCategories();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final categoryNotifierProvider = NotifierProvider<CategoryNotifier, AsyncValue<void>>(() {
  return CategoryNotifier();
});

final categoryInitializationProvider = FutureProvider<void>((ref) async {
  await CategoryService.initializeDefaultCategories();
});