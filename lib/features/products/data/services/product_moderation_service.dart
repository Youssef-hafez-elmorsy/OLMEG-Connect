import 'package:cloud_functions/cloud_functions.dart';

class ProductModerationResult {
  final bool approved;
  final double confidence;
  final List<String> reasons;
  final double riskScore;
  final String riskLevel;
  final String suggestedAction;
  final List<String> signals;
  final List<String> sellerHints;
  final String provider;
  final String model;

  const ProductModerationResult({
    required this.approved,
    required this.confidence,
    required this.reasons,
    this.riskScore = 0,
    this.riskLevel = 'low',
    this.suggestedAction = 'approve',
    this.signals = const [],
    this.sellerHints = const [],
    this.provider = 'local_rules',
    this.model = 'local_rules_v1',
  });
}

class ProductModerationService {
  static const _blockedTerms = [
    'weapon',
    'gun',
    'rifle',
    'pistol',
    'knife',
    'drugs',
    'cocaine',
    'fake id',
    'passport',
    'stolen',
    'counterfeit',
    'hack',
    'explosive',
  ];

  ProductModerationResult review({
    required String title,
    required String description,
    required double price,
  }) {
    final reasons = <String>[];
    final text = '$title $description'.toLowerCase();

    if (title.trim().length < 3) {
      reasons.add('Title is too short.');
    }

    if (description.trim().length < 10) {
      reasons.add('Description is too short.');
    }

    if (price <= 0) {
      reasons.add('Price must be greater than zero.');
    }

    for (final term in _blockedTerms) {
      if (text.contains(term)) {
        reasons.add('Possible restricted item: "$term".');
      }
    }

    return ProductModerationResult(
      approved: reasons.isEmpty,
      confidence: reasons.isEmpty ? 0.92 : 0.84,
      riskScore: reasons.isEmpty ? 0.08 : 0.72,
      riskLevel: reasons.isEmpty ? 'low' : 'high',
      suggestedAction: reasons.isEmpty ? 'approve' : 'admin_review',
      reasons: reasons,
      signals: reasons.isEmpty ? const [] : const ['local_rule_match'],
      sellerHints: reasons.isEmpty
          ? const []
          : const [
              'Update the listing details so staff can quickly verify it.',
            ],
    );
  }
}

class ProductAiModerationService {
  final FirebaseFunctions _functions;
  final ProductModerationService _fallback;

  ProductAiModerationService({
    FirebaseFunctions? functions,
    ProductModerationService? fallback,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _fallback = fallback ?? ProductModerationService();

  Future<ProductModerationResult> review({
    required String productId,
    required String title,
    required String description,
    required double price,
    String? category,
    String? subcategory,
    String? location,
    String? imageUrl,
  }) async {
    final localReview = _fallback.review(
      title: title,
      description: description,
      price: price,
    );

    try {
      final callable = _functions.httpsCallable('analyzeProductWithAi');
      final response = await callable.call<Map<String, dynamic>>({
        'productId': productId,
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'subcategory': subcategory,
        'location': location,
        'imageUrl': imageUrl,
      });
      final payload = response.data;
      final review = Map<String, dynamic>.from(
        payload['review'] as Map? ?? const {},
      );
      if (review.isEmpty) return localReview;

      return ProductModerationResult(
        approved: review['approved'] == true,
        confidence: _num(review['confidence'], localReview.confidence),
        riskScore: _num(review['riskScore'], localReview.riskScore),
        riskLevel: _string(review['riskLevel'], localReview.riskLevel),
        suggestedAction:
            _string(review['suggestedAction'], localReview.suggestedAction),
        reasons: _strings(review['reasons']),
        signals: _strings(review['signals']),
        sellerHints: _strings(review['sellerHints']),
        provider: _string(review['provider'], 'openai_responses'),
        model: _string(review['model'], 'unknown'),
      );
    } catch (_) {
      return localReview;
    }
  }

  static double _num(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  static String _string(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .map((item) => item.trim())
        .toList(growable: false);
  }
}
