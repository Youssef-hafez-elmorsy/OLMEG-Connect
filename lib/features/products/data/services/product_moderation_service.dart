class ProductModerationResult {
  final bool approved;
  final double confidence;
  final List<String> reasons;

  const ProductModerationResult({
    required this.approved,
    required this.confidence,
    required this.reasons,
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
      reasons: reasons,
    );
  }
}
