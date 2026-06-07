import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('capacity readiness guards', () {
    test('chat inbox query is scoped to the signed-in participant', () {
      final source = File(
        'lib/features/chat/data/datasources/chat_remote_datasource.dart',
      ).readAsStringSync();

      expect(source, contains(".where('participants', arrayContains: userId)"));
      expect(
        source,
        isNot(contains('get all chats and filter by participants')),
      );
    });

    test('product discovery uses bounded category queries', () {
      final source = File(
        'lib/features/products/data/datasources/product_remote_datasource.dart',
      ).readAsStringSync();

      expect(source, contains('static const int productListLimit = 80'));
      expect(source, contains("_fieldQuery('categoryId', filterId)"));
      expect(source, contains("_fieldQuery('subCategoryId', filterId)"));
      expect(source, contains("_fieldQuery('categoryName', filterId)"));
      expect(source, contains('take(productListLimit)'));
    });

    test('product view tracking avoids hot product document increments', () {
      final source = File(
        'lib/features/products/presentation/screens/product_detail_screen.dart',
      ).readAsStringSync();

      final hotCounterPattern = RegExp(
        r"collection\('products'\)\s*\.doc\(widget\.product\.id\)[\s\S]*viewCount",
      );
      expect(hotCounterPattern.hasMatch(source), isFalse);
      expect(source, contains('trackProductViewed'));
    });

    test('screen performance telemetry is sampled in production', () {
      final source = File(
        'lib/core/widgets/screen_performance_probe.dart',
      ).readAsStringSync();

      expect(source, contains('EnvironmentConfig.isProduction'));
      expect(source, contains('seed % 20 == 0'));
    });

    test('Firestore indexes cover capacity queries', () {
      final raw = File('firestore.indexes.json').readAsStringSync();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final indexes = (data['indexes'] as List).cast<Map<String, dynamic>>();

      bool hasIndex(String collection, List<String> fields) {
        return indexes.any((index) {
          if (index['collectionGroup'] != collection) return false;
          final indexFields = (index['fields'] as List)
              .cast<Map<String, dynamic>>()
              .map((field) => field['fieldPath'] as String)
              .toList();
          return fields.every(indexFields.contains);
        });
      }

      expect(hasIndex('chats', ['participants', 'updatedAt']), isTrue);
      expect(hasIndex('products', ['categoryId', 'createdAt']), isTrue);
      expect(hasIndex('products', ['subCategoryId', 'createdAt']), isTrue);
      expect(hasIndex('products', ['categoryName', 'createdAt']), isTrue);
    });
  });
}
