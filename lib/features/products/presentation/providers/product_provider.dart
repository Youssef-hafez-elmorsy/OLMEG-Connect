import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/product_usecases.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(productRemoteDataSourceProvider));
});

final getProductsUseCaseProvider = Provider((ref) => GetProductsUseCase(ref.watch(productRepositoryProvider)));
final getUserProductsUseCaseProvider = Provider((ref) => GetUserProductsUseCase(ref.watch(productRepositoryProvider)));
final addProductUseCaseProvider = Provider((ref) => AddProductUseCase(ref.watch(productRepositoryProvider)));
final deleteProductUseCaseProvider = Provider((ref) => DeleteProductUseCase(ref.watch(productRepositoryProvider)));

class CategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void selectCategory(String category) {
    state = category;
  }
}

final selectedCategoryProvider = NotifierProvider<CategoryNotifier, String>(() {
  return CategoryNotifier();
});

final productsStreamProvider = StreamProvider.family<List<ProductEntity>, String?>((ref, categoryId) {
  final useCase = ref.watch(getProductsUseCaseProvider);
  return useCase(categoryId: categoryId);
});

final userProductsStreamProvider = StreamProvider.family<List<ProductEntity>, String>((ref, userId) {
  return ref.watch(getUserProductsUseCaseProvider)(userId);
});

class AddProductNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String?> addProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    state = const AsyncValue.loading();
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      state = const AsyncValue.data(null);
      return 'User not authenticated';
    }
    final addProductUseCase = ref.read(addProductUseCaseProvider);
    final product = ProductEntity(
      id: const Uuid().v4(),
      title: title,
      description: description,
      price: price,
      category: category,
      imageUrl: '',
      sellerId: user.id,
      sellerName: user.name,
      createdAt: DateTime.now(),
    );
    final result = await addProductUseCase(product: product, imageFile: imageFile, imageBytes: imageBytes);
    return result.fold(
      (failure) {
        state = const AsyncValue.data(null);
        return failure.message;
      },
      (_) {
        state = const AsyncValue.data(null);
        return null;
      },
    );
  }
}

final addProductNotifierProvider = NotifierProvider<AddProductNotifier, AsyncValue<void>>(() {
  return AddProductNotifier();
});

class FavoriteNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> toggleFavorite(String productId) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;
      final favoriteRef = firestore.collection('favorites').doc('${user.id}_$productId');

      final doc = await favoriteRef.get();
      if (doc.exists) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set({
          'userId': user.id,
          'productId': productId,
          'createdAt': DateTime.now(),
        });
      }
    } catch (e) {
      // Silently fail
    }
  }
}

final favoriteNotifierProvider = NotifierProvider<FavoriteNotifier, AsyncValue<void>>(() {
  return FavoriteNotifier();
});