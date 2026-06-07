import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/core/services/ai_marketplace_service.dart';
import 'package:olmeg_connect/features/auth/domain/entities/merchant_verification_entity.dart';
import 'package:olmeg_connect/features/products/data/models/product_model.dart';
import 'package:olmeg_connect/features/products/domain/entities/product_entity.dart';
import 'package:olmeg_connect/features/search/domain/entities/search_filter_entity.dart';

abstract class SearchRemoteDataSource {
  Future<List<ProductEntity>> searchProducts(SearchFilterEntity filter);
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final FirebaseFirestore firestore;
  final AiMarketplaceService aiService;

  SearchRemoteDataSourceImpl({
    required this.firestore,
    AiMarketplaceService? aiService,
  }) : aiService = aiService ?? AiMarketplaceService();

  static const Map<String, List<String>> _synonyms = {
    'cheap': ['cheap', 'affordable', 'budget', 'low price', 'رخيص', 'اقتصادي'],
    'phone': ['phone', 'mobile', 'smartphone', 'موبايل', 'هاتف', 'تليفون'],
    'laptop': ['laptop', 'notebook', 'computer', 'لاب توب', 'كمبيوتر محمول'],
    'battery': ['battery', 'بطارية'],
    'charger': ['charger', 'شاحن'],
    'handmade': [
      'handmade',
      'handcraft',
      'handicraft',
      'craft',
      'مصنوع يدوي',
      'هاند ميد',
      'حرفي'
    ],
    'clothes': ['clothes', 'fashion', 'apparel', 'ملابس', 'هدوم', 'ازياء'],
    'shoes': ['shoes', 'sneakers', 'footwear', 'احذية', 'جزمة', 'كوتشي'],
    'bag': ['bag', 'purse', 'backpack', 'شنطة', 'حقيبة'],
    'home': ['home', 'house', 'decor', 'منزل', 'بيت', 'ديكور'],
  };

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
            final moderationStatus = data['moderationStatus'] as String?;
            final status = data['status'] as String?;
            final publishStatus = data['publishStatus'] as String?;
            final isDiscoverable = status != 'draft' &&
                status != 'scheduled' &&
                publishStatus != 'draft' &&
                publishStatus != 'scheduled';
            return isDiscoverable &&
                (moderationStatus == null || moderationStatus == 'approved');
          })
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      final terms = await _expandedTerms(filter.query);

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

      if (filter.sellerId != null && filter.sellerId!.isNotEmpty) {
        results = results.where((p) => p.sellerId == filter.sellerId).toList();
      }

      if (filter.onlyAvailable == true) {
        results = results.where((p) => p.inStock).toList();
      }

      if (filter.minRating != null) {
        results =
            results.where((p) => p.ratingAverage >= filter.minRating!).toList();
      }

      // Apply price range filter client-side
      if (filter.minPrice != null) {
        results = results.where((p) => p.price >= filter.minPrice!).toList();
      }
      if (filter.maxPrice != null) {
        results = results.where((p) => p.price <= filter.maxPrice!).toList();
      }

      // Apply text search client-side
      if (terms.isNotEmpty) {
        results = results
            .where((product) => terms.any((term) => _matches(product, term)))
            .toList();
      }

      switch (filter.sortBy) {
        case 'relevance':
          results.sort((a, b) {
            final score = _score(b, terms).compareTo(_score(a, terms));
            return score == 0 ? b.createdAt.compareTo(a.createdAt) : score;
          });
          break;
        case 'price_low':
          results.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_high':
          results.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          results.sort((a, b) {
            final rating = b.ratingAverage.compareTo(a.ratingAverage);
            return rating == 0
                ? _score(b, terms).compareTo(_score(a, terms))
                : rating;
          });
          break;
        case 'availability':
          results.sort((a, b) {
            if (a.inStock == b.inStock) {
              return b.createdAt.compareTo(a.createdAt);
            }
            return a.inStock ? -1 : 1;
          });
          break;
        case 'discount':
          results
              .sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
          break;
        case 'newest':
        default:
          if (terms.isNotEmpty) {
            results.sort((a, b) {
              final score = _score(b, terms).compareTo(_score(a, terms));
              return score == 0 ? b.createdAt.compareTo(a.createdAt) : score;
            });
          } else {
            results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
      }

      return results;
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  Future<List<String>> _expandedTerms(String? query) async {
    final normalized = query?.toLowerCase().trim() ?? '';
    if (normalized.isEmpty) return const [];
    final terms = <String>{normalized};
    for (final token in normalized.split(RegExp(r'\s+'))) {
      if (token.trim().isEmpty) continue;
      terms.add(token);
      for (final entry in _synonyms.entries) {
        if (entry.key == token || entry.value.contains(token)) {
          terms.addAll(entry.value);
        }
      }
    }
    final aiIntent = await aiService.expandSearchQuery(normalized);
    if (aiIntent != null) {
      terms.add(aiIntent.normalizedQuery.toLowerCase());
      terms.addAll(aiIntent.expandedTerms.map((term) => term.toLowerCase()));
      terms.addAll(aiIntent.categoryHints.map((term) => term.toLowerCase()));
    }
    return terms.where((term) => term.trim().isNotEmpty).toList();
  }

  bool _matches(ProductEntity product, String term) {
    final target = [
      product.title,
      product.description,
      product.category,
      product.categoryId ?? '',
      product.subcategory ?? '',
      product.subCategoryName ?? '',
      product.brand ?? '',
      product.features.join(' '),
    ].join(' ').toLowerCase();
    return target.contains(term);
  }

  double _score(ProductEntity product, List<String> terms) {
    var score = 0.0;
    for (final term in terms) {
      if (product.title.toLowerCase().contains(term)) score += 10;
      if (product.description.toLowerCase().contains(term)) score += 4;
      if (product.category.toLowerCase().contains(term)) score += 6;
      if (product.subCategoryName?.toLowerCase().contains(term) ?? false) {
        score += 6;
      }
      if (product.brand?.toLowerCase().contains(term) ?? false) score += 4;
    }
    if (product.inStock) score += 3;
    if (product.status == 'sponsored' || product.status == 'promoted') {
      score += 2;
    }
    score += product.ratingAverage * 1.5;
    if (product.sellerMerchantVerificationStatus ==
        MerchantVerificationStatus.approved) {
      score += 2;
    }
    final age = DateTime.now().difference(product.createdAt).inDays;
    if (age <= 7) {
      score += 3;
    } else if (age <= 30) {
      score += 1;
    }
    return score;
  }
}
