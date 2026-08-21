import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import '../features/landing/landing_page.dart';
import '../widgets/mandatory_upgrade_alert.dart';

class WhatsAppSenderApp extends StatefulWidget {
  const WhatsAppSenderApp({super.key, this.enableUpgrader = true});

  final bool enableUpgrader;

  @override
  State<WhatsAppSenderApp> createState() => _WhatsAppSenderAppState();
}

class _WhatsAppSenderAppState extends State<WhatsAppSenderApp> {
  late final Upgrader? _upgrader = widget.enableUpgrader && kReleaseMode
      ? Upgrader(
          checkOnResume: true,
          countryCode: 'IN',
          durationUntilAlertAgain: Duration.zero,
        )
      : null;

  @override
  void dispose() {
    _upgrader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = _upgrader == null
        ? const LandingPage()
        : MandatoryUpgradeAlert(
            upgrader: _upgrader,
            child: const LandingPage(),
          );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EfforTrak Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF128C7E)),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
