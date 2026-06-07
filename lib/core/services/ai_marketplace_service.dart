import 'package:cloud_functions/cloud_functions.dart';

class AiSearchIntent {
  final String normalizedQuery;
  final List<String> expandedTerms;
  final List<String> categoryHints;
  final String buyerIntent;
  final String provider;
  final String model;

  const AiSearchIntent({
    required this.normalizedQuery,
    required this.expandedTerms,
    required this.categoryHints,
    required this.buyerIntent,
    required this.provider,
    required this.model,
  });

  factory AiSearchIntent.fromMap(Map<String, dynamic> map) {
    return AiSearchIntent(
      normalizedQuery: _string(map['normalizedQuery']),
      expandedTerms: _strings(map['expandedTerms']),
      categoryHints: _strings(map['categoryHints']),
      buyerIntent: _string(map['buyerIntent'], fallback: 'browse'),
      provider: _string(map['provider'], fallback: 'local_rules'),
      model: _string(map['model'], fallback: 'local_rules_v1'),
    );
  }
}

class AiRecommendationResult {
  final List<String> productIds;
  final String explanation;
  final String provider;
  final String model;

  const AiRecommendationResult({
    required this.productIds,
    required this.explanation,
    required this.provider,
    required this.model,
  });

  factory AiRecommendationResult.fromMap(Map<String, dynamic> map) {
    return AiRecommendationResult(
      productIds: _strings(map['productIds']),
      explanation: _string(map['explanation']),
      provider: _string(map['provider'], fallback: 'local_rules'),
      model: _string(map['model'], fallback: 'local_rules_v1'),
    );
  }
}

class AiSellerHints {
  final List<String> titleSuggestions;
  final List<String> descriptionSuggestions;
  final List<String> pricingSignals;
  final List<String> trustSignals;
  final String provider;
  final String model;

  const AiSellerHints({
    required this.titleSuggestions,
    required this.descriptionSuggestions,
    required this.pricingSignals,
    required this.trustSignals,
    required this.provider,
    required this.model,
  });

  factory AiSellerHints.fromMap(Map<String, dynamic> map) {
    return AiSellerHints(
      titleSuggestions: _strings(map['titleSuggestions']),
      descriptionSuggestions: _strings(map['descriptionSuggestions']),
      pricingSignals: _strings(map['pricingSignals']),
      trustSignals: _strings(map['trustSignals']),
      provider: _string(map['provider'], fallback: 'local_rules'),
      model: _string(map['model'], fallback: 'local_rules_v1'),
    );
  }
}

class AiMarketplaceService {
  final FirebaseFunctions _functions;

  AiMarketplaceService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<AiSearchIntent?> expandSearchQuery(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final result = await _functions.httpsCallable('expandSearchWithAi').call({
        'query': query.trim(),
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final intent = Map<String, dynamic>.from(data['intent'] as Map? ?? {});
      return AiSearchIntent.fromMap(intent);
    } catch (_) {
      return null;
    }
  }

  Future<AiRecommendationResult?> recommendations({
    required List<String> signalProductIds,
  }) async {
    try {
      final result =
          await _functions.httpsCallable('getBuyerRecommendationsWithAi').call({
        'signalProductIds': signalProductIds.take(30).toList(),
      });
      return AiRecommendationResult.fromMap(
        Map<String, dynamic>.from(result.data as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<AiSellerHints?> sellerHints({
    required String title,
    required String description,
    required double price,
    String? category,
    String? subcategory,
    String? location,
  }) async {
    try {
      final result =
          await _functions.httpsCallable('getSellerListingHintsWithAi').call({
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'subcategory': subcategory,
        'location': location,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final hints = Map<String, dynamic>.from(data['hints'] as Map? ?? {});
      return AiSellerHints.fromMap(hints);
    } catch (_) {
      return null;
    }
  }
}

String _string(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .where((item) => item.trim().isNotEmpty)
      .map((item) => item.trim())
      .toList(growable: false);
}
