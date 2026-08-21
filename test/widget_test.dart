import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whats_app/app/whats_app.dart';
import 'package:whats_app/features/create_contact/create_contact_page.dart';

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
    expect(find.text('Manage WhatsApp templates'), findsOneWidget);
  });

  testWidgets('opens WhatsApp template manager from home', (tester) async {
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage WhatsApp templates'));
    await tester.pumpAndSettle();

    expect(find.text('WhatsApp templates'), findsOneWidget);
    expect(
      find.text('Hello, I wanted to contact you regarding your request.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Add template'), findsWidgets);
  });

  testWidgets('opens the compact manual contact screen', (tester) async {
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();

    expect(find.text('Add contact manually'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Send message'), findsOneWidget);
    expect(find.text('Send my card'), findsOneWidget);
    expect(find.text('Save contact'), findsOneWidget);
    expect(find.text('Quick message'), findsNothing);
  });

  testWidgets('opens the create your contact card form', (tester) async {
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create your contact'));
    await tester.pumpAndSettle();

    expect(find.text('Your contact QR'), findsNothing);
    expect(find.text('Name *'), findsOneWidget);
    expect(find.text('Phone number *'), findsOneWidget);
    expect(find.text('Alternate contact number'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Website'), findsOneWidget);
    final verticalScrollable = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .last;
    await tester.scrollUntilVisible(
      find.text('LinkedIn'),
      300,
      scrollable: verticalScrollable,
    );
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('LinkedIn'), findsOneWidget);
    expect(find.text('Short bio'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save to phone'),
      250,
      scrollable: verticalScrollable,
    );
    expect(find.text('Save to phone'), findsOneWidget);
  });

  testWidgets('shows saved contact QR and compact edit link on home', (
    tester,
  ) async {
    await const ContactCardData(
      name: 'Asha Sen',
      phone: '9876543210',
      email: 'asha@example.com',
    ).save();

    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();

    expect(find.text('Scan to add this contact'), findsOneWidget);
    expect(find.text('Asha Sen'), findsOneWidget);
    expect(find.byKey(const ValueKey('qr-center-logo')), findsOneWidget);
    expect(find.text('Edit your contact'), findsOneWidget);
    expect(find.text('Create your contact'), findsNothing);
  });

  testWidgets('opens saved contact QR full screen on double tap', (
    tester,
  ) async {
    await const ContactCardData(name: 'Asha Sen', phone: '9876543210').save();
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('contact-qr-preview')),
      pointer: 1,
    );
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(
      find.byKey(const ValueKey('contact-qr-preview')),
      pointer: 1,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('full-screen-contact-qr')),
      findsOneWidget,
    );
    expect(find.text('Double-tap anywhere to close'), findsOneWidget);
  });

  testWidgets('shows quick messages only when WhatsApp is selected', (
    tester,
  ) async {
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();

    expect(find.text('Quick message'), findsOneWidget);
    expect(find.text('Hi.'), findsOneWidget);
  });

  testWidgets('allows either or both send options to be selected', (
    tester,
  ) async {
    await const ContactCardData(name: 'Asha Sen', phone: '9876543210').save();
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send my card'));
    await tester.pumpAndSettle();
    var checkboxes = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .toList();
    expect(checkboxes[0].value, isFalse);
    expect(checkboxes[1].value, isTrue);

    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();
    checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(checkboxes[0].value, isTrue);
    expect(checkboxes[1].value, isTrue);
  });

  testWidgets('creates and selects a new WhatsApp template', (tester) async {
    await tester.pumpWidget(const WhatsAppSenderApp(enableUpgrader: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send message'));
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
