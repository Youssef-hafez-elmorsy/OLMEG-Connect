import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Storage rules static guards', () {
    late String rules;

    setUpAll(() {
      rules = File('storage.rules').readAsStringSync();
    });

    test('merchant verification documents are owner or admin staff only', () {
      expect(
          rules, contains('match /merchant_verification/{userId}/{fileName}'));
      expect(
          rules, contains('allow read: if isOwner(userId) || isAdminStaff();'));
      expect(
        rules,
        contains(
            'allow write: if (isOwner(userId) || isAdmin()) && validMerchantDocument();'),
      );
    });

    test('uploads enforce file type and size limits', () {
      expect(rules, contains('function validImage(maxBytes)'));
      expect(
          rules, contains("request.resource.contentType.matches('image/.*')"));
      expect(rules, contains('function validMerchantDocument()'));
      expect(
          rules,
          contains(
              "request.resource.contentType.matches('image/.*|application/pdf')"));
    });

    test('product image writes are scoped to the seller path owner', () {
      expect(rules, contains('match /product_images/{userId}/{fileName}'));
      expect(rules, contains('allow read: if true;'));
      expect(
        rules,
        contains(
            'allow write: if isOwner(userId) && validImage(8 * 1024 * 1024);'),
      );
    });

    test('storage fallback is deny by default', () {
      expect(rules, contains('match /{allPaths=**}'));
      expect(rules, contains('allow read, write: if false;'));
    });
  });
}
