import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdd_webchat_o/features/chat/domain/chat_message.dart';
import 'package:sdd_webchat_o/features/chat/presentation/chat_screen.dart';
import 'package:sdd_webchat_o/features/chat/presentation/providers/chat_controller.dart';

void main() {
  group('Chat acceptance', () {
    testWidgets('shows live progress while sending', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatControllerProvider.overrideWith(_SendingChatController.new),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('検索中... (1/3)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('hides progress bar when idle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatControllerProvider.overrideWith(_IdleChatController.new),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('検索中'), findsNothing);
    });

    testWidgets('chat options reflect searxng toggle state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatControllerProvider.overrideWith(
              _SearchEnabledChatController.new,
            ),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      expect(find.text('SearXNG'), findsOneWidget);
      expect(find.text('ON'), findsOneWidget);
    });
  });
}

class _SendingChatController extends ChatController {
  @override
  ChatState build() {
    return ChatState(
      conversationId: 'sending_conv',
      title: 'Sending',
      messages: [ChatMessage(role: 'assistant', content: '処理を開始します。')],
      isSending: true,
      searxngEnabled: true,
      progressText: '検索中... (1/3)',
    );
  }
}

class _IdleChatController extends ChatController {
  @override
  ChatState build() {
    return ChatState(
      conversationId: 'idle_conv',
      title: 'Idle',
      messages: [ChatMessage(role: 'assistant', content: '完了しました。')],
      isSending: false,
      searxngEnabled: false,
      progressText: '',
    );
  }
}

class _SearchEnabledChatController extends ChatController {
  @override
  ChatState build() {
    return ChatState(
      conversationId: 'search_conv',
      title: 'Search',
      messages: [ChatMessage(role: 'assistant', content: '検索待機中。')],
      isSending: false,
      searxngEnabled: true,
      progressText: '',
    );
  }
}
