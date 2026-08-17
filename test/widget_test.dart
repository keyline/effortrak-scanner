import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whats_app/app/whats_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PackageInfo.setMockInitialValues(
      appName: 'EfforTrak Scanner',
      packageName: 'com.keyline.quickwa',
      version: '1.0.1',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  testWidgets('renders the contact landing screen', (tester) async {
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();

    expect(find.text('EfforTrak Scanner'), findsOneWidget);
    expect(find.text('Scan a card'), findsOneWidget);
    expect(find.text('Add manually'), findsOneWidget);
    expect(find.text('Version 1.0.1'), findsOneWidget);
  });

  testWidgets('opens the compact manual contact screen', (tester) async {
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();

    expect(find.text('Add contact manually'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Send WhatsApp'), findsOneWidget);
    expect(find.text('Save contact'), findsOneWidget);
    expect(find.text('Quick message'), findsNothing);
  });

  testWidgets('shows quick messages only when WhatsApp is selected', (
    tester,
  ) async {
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send WhatsApp'));
    await tester.pumpAndSettle();

    expect(find.text('Quick message'), findsOneWidget);
    expect(find.text('Select a saved message'), findsOneWidget);
  });

  testWidgets('creates and selects a new WhatsApp template', (tester) async {
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send WhatsApp'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New template'));
    await tester.pumpAndSettle();
    expect(find.text('Create new template'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      'Thank you for sharing your business card.',
    );
    await tester.tap(find.text('Save template'));
    await tester.pumpAndSettle();

    expect(find.text('Create new template'), findsNothing);
    expect(
      find.text('Thank you for sharing your business card.'),
      findsOneWidget,
    );
  });
}
