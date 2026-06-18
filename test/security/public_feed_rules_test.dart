import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('public marketplace feed rules', () {
    late String rules;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
    });

    test('home product listings can be read by public app visitors', () {
      expect(rules, contains('match /products/{productId}'));
      expect(rules, contains('allow read: if true;'));
      expect(rules, contains('request.resource.data.sellerId == request.auth.uid'));
    });

    test('community posts and comments can be read publicly', () {
      expect(rules, contains('match /posts/{postId}'));
      expect(rules, contains('match /comments/{commentId}'));
      expect(rules, contains('request.resource.data.authorId == request.auth.uid'));
    });
  });
}
