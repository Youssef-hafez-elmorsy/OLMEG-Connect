import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chat rules static guards', () {
    late String rules;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
    });

    test('messages are scoped under participant-only conversations', () {
      expect(rules, contains('match /chats/{chatId}'));
      expect(rules, contains('match /messages/{messageId}'));
      expect(rules, contains('isChatParticipantById(chatId)'));
      expect(rules, contains('allow read: if isChatParticipantById(chatId);'));
    });

    test('message creation prevents sender spoofing and empty content', () {
      expect(rules, contains('validChatMessageCreate(chatId)'));
      expect(rules,
          contains('request.resource.data.senderId == request.auth.uid'));
      expect(rules, contains('request.resource.data.conversationId == chatId'));
      expect(rules, contains('request.resource.data.content.size() > 0'));
      expect(rules, contains('request.resource.data.content.size() <= 1200'));
    });

    test('participants cannot edit protected conversation metadata', () {
      expect(rules, contains('safeChatUpdate()'));
      expect(rules, contains('affectedKeys().hasOnly'));
      expect(rules, isNot(contains("'buyerId',\n          'sellerId'")));
      expect(rules, isNot(contains("'productId',\n          'productTitle'")));
    });

    test('chat reports require participant reporter and reason', () {
      expect(rules, contains('validChatReportCreate()'));
      expect(rules,
          contains('request.resource.data.reporterId == request.auth.uid'));
      expect(rules, contains('request.resource.data.reason.size() > 0'));
      expect(rules, contains('targetType'));
      expect(rules, contains('conversationId'));
    });
  });
}
