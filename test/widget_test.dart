import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdd_webchat_o/app/app.dart';

void main() {
  testWidgets('app renders navigation tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SddWebchatApp()));
    await tester.pumpAndSettle();

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
