import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whats_app/app/whats_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders the WhatsApp sender home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WhatsAppSenderApp());
    await tester.pumpAndSettle();

    expect(find.text('Direct WhatsApp'), findsOneWidget);
    expect(find.text('Receiver Number'), findsOneWidget);
    expect(find.text('Quick Message'), findsWidgets);
    expect(find.text('Open WhatsApp'), findsOneWidget);
  });

  testWidgets('switches to custom message mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WhatsAppSenderApp());
    await tester.pumpAndSettle();

    expect(find.text('Choose Message'), findsOneWidget);
    expect(find.text('Custom Message'), findsOneWidget);

    await tester.tap(find.text('Custom Message').first);
    await tester.pumpAndSettle();

    expect(find.text('Type your message and send'), findsOneWidget);
    expect(find.text('Choose Message'), findsNothing);
  });
}
