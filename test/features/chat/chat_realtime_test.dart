import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('real-time chat implementation guards', () {
    late String datasource;
    late String model;

    setUpAll(() {
      datasource = File(
        'lib/features/chat/data/datasources/chat_remote_datasource.dart',
      ).readAsStringSync();
      model = File('lib/features/chat/data/models/chat_model.dart')
          .readAsStringSync();
    });

    test('messages are written to a subcollection, not array-unioned', () {
      expect(datasource, contains(".collection('messages')"));
      expect(datasource, contains('transaction.set(messageRef, message)'));
      expect(datasource, isNot(contains('FieldValue.arrayUnion([message])')));
    });

    test('conversation summary fields are maintained for inbox updates', () {
      expect(datasource, contains("'latestMessagePreview'"));
      expect(datasource, contains("'latestMessageAt'"));
      expect(datasource, contains("'latestMessageSenderId'"));
      expect(datasource, contains("'unreadBy'"));
    });

    test('legacy embedded messages remain readable during migration', () {
      expect(model, contains('legacyMessages'));
      expect(model, contains('messages ?? legacyMessages'));
      expect(model, contains('orderedMessages'));
    });
  });
}
