import 'package:flutter_test/flutter_test.dart';
import 'package:security_news/main.dart';

void main() {
  testWidgets('CyberWatchApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CyberWatchApp());

    // Verify that our app name is present.
    expect(find.text('CYBERWATCH'), findsOneWidget);
  });
}
