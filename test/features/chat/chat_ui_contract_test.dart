import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chat UI contract guards', () {
    late String detail;
    late String list;
    late String l10n;

    setUpAll(() {
      detail = File(
        'lib/features/chat/presentation/screens/chat_detail_screen.dart',
      ).readAsStringSync();
      list = File(
        'lib/features/chat/presentation/screens/chat_list_screen.dart',
      ).readAsStringSync();
      l10n = File('lib/core/localization/app_localizations.dart')
          .readAsStringSync();
    });

    test('conversation detail exposes participant safety actions only', () {
      expect(detail, contains('muteConversation'));
      expect(detail, contains('blockConversation'));
      expect(detail, contains('reportConversation'));
      expect(detail, isNot(contains('/admin')));
      expect(detail, isNot(contains('Admin')));
    });

    test('message bubbles are reportable and show delivery state', () {
      expect(detail, contains('onLongPress: onReport'));
      expect(detail, contains("status == 'failed'"));
      expect(detail, contains('Icons.done_all'));
    });

    test('inbox uses safe latest preview and unread indicators', () {
      expect(list, contains('chat.safeLatestPreview'));
      expect(list, contains('chat.unreadBy.contains(currentUserId)'));
      expect(list, contains('Icons.notifications_off_outlined'));
      expect(list, contains('Icons.block_outlined'));
    });

    test('chat strings include Arabic and English safety/report keys', () {
      expect(l10n, contains("'reportConversation'"));
      expect(l10n, contains("'conversationReported'"));
      expect(l10n, contains("'blockedNotice'"));
      expect(l10n, contains('إرسال البلاغ'));
    });
  });
}
