import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdd_webchat_o/app/app.dart';

void main() {
  testWidgets('app renders chat screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SddWebchatApp()));
    await tester.pumpAndSettle();

    expect(find.text('New Conversation'), findsOneWidget);
    expect(find.text('メッセージを送信すると会話が始まります。'), findsOneWidget);
  });
}
