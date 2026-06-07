import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI marketplace upgrade', () {
    late String aiServices;
    late String index;
    late String addProduct;
    late String moderation;
    late String adminModeration;

    setUpAll(() {
      aiServices = File('functions/aiServices.js').readAsStringSync();
      index = File('functions/index.js').readAsStringSync();
      addProduct = File(
        'lib/features/products/presentation/screens/add_product_screen.dart',
      ).readAsStringSync();
      moderation = File(
        'lib/features/products/data/services/product_moderation_service.dart',
      ).readAsStringSync();
      adminModeration = File(
        'apps/admin_web/lib/features/moderation/product_moderation_screen.dart',
      ).readAsStringSync();
    });

    test('backend exposes OpenAI-backed callable with local fallback', () {
      expect(index, contains("require('./aiServices')"));
      expect(index, contains('Object.assign(exports, aiServices)'));
      expect(aiServices, contains('analyzeProductWithAi'));
      expect(aiServices, contains('expandSearchWithAi'));
      expect(aiServices, contains('getBuyerRecommendationsWithAi'));
      expect(aiServices, contains('getSellerListingHintsWithAi'));
      expect(aiServices, contains('adminAskAssistantWithAi'));
      expect(aiServices, contains('OPENAI_API_KEY'));
      expect(aiServices, contains('OPENAI_MODEL'));
      expect(aiServices, contains('openai_responses'));
      expect(aiServices, contains('local_rules'));
      expect(aiServices, contains('text: { format: REVIEW_SCHEMA }'));
      expect(aiServices, contains('ai_moderation_reviews'));
      expect(aiServices, contains('admin_ai_assistant_asked'));
    });

    test('seller listing flow stores explainable AI moderation evidence', () {
      expect(moderation, contains('ProductAiModerationService'));
      expect(moderation, contains("httpsCallable('analyzeProductWithAi')"));
      expect(addProduct, contains('ProductAiModerationService().review'));
      expect(addProduct, contains("'aiRiskScore': moderation.riskScore"));
      expect(addProduct, contains("'aiRiskLevel': moderation.riskLevel"));
      expect(addProduct,
          contains("'aiSuggestedAction': moderation.suggestedAction"));
      expect(addProduct, contains("'aiReasons': moderation.reasons"));
      expect(addProduct, contains("'aiSellerHints': moderation.sellerHints"));
      expect(addProduct, contains('AI seller hints'));
    });

    test('admin moderation queue displays AI risk evidence', () {
      expect(adminModeration, contains("AdminTableColumn.field('AI Risk'"));
      expect(adminModeration, contains("AdminTableColumn.field('AI Action'"));
      expect(adminModeration, contains("AdminTableColumn.field('AI Reasons'"));
      expect(adminModeration, contains("AdminTableColumn.field('AI Signals'"));
    });
  });
}
