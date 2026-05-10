import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/products/data/models/product_model.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/search/domain/entities/search_filter_entity.dart';

abstract class SearchRemoteDataSource {
  Future<List<ProductEntity>> searchProducts(SearchFilterEntity filter);
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final FirebaseFirestore firestore;

  SearchRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<ProductEntity>> searchProducts(SearchFilterEntity filter) async {
    try {
      final snapshot = await firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      var results = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final status = data['moderationStatus'] as String?;
            return status == null || status == 'approved';
          })
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      if (filter.category != null && filter.category!.isNotEmpty) {
        final category = filter.category!.toLowerCase().trim();
        results = results.where((p) {
          return p.category.toLowerCase().contains(category) ||
              (p.categoryId?.toLowerCase() == category) ||
              (p.subcategory?.toLowerCase().contains(category) ?? false) ||
              (p.subCategoryId?.toLowerCase() == category) ||
              (p.subCategoryName?.toLowerCase().contains(category) ?? false);
        }).toList();
      }

      if (filter.condition != null && filter.condition!.isNotEmpty) {
        final condition = filter.condition!.toLowerCase().trim();
        results = results
            .where((p) => p.condition?.toLowerCase() == condition)
            .toList();
      }

      if (filter.location != null && filter.location!.isNotEmpty) {
        final location = filter.location!.toLowerCase().trim();
        results = results
            .where((p) => p.city.toLowerCase().contains(location))
            .toList();
      }

      // Apply price range filter client-side
      if (filter.minPrice != null) {
        results = results.where((p) => p.price >= filter.minPrice!).toList();
      }
      if (filter.maxPrice != null) {
        results = results.where((p) => p.price <= filter.maxPrice!).toList();
      }

      // Apply text search client-side
      if (filter.query != null && filter.query!.isNotEmpty) {
        final query = filter.query!.toLowerCase();
        results = results
            .where((p) =>
                p.title.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query) ||
                (p.subCategoryName?.toLowerCase().contains(query) ?? false))
            .toList();
      }

      switch (filter.sortBy) {
        case 'price_low':
          results.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_high':
          results.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          results.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'newest':
        default:
          results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      return results;
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }
}
