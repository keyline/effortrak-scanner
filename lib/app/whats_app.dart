import 'package:flutter/material.dart';

import '../features/landing/landing_page.dart';

class WhatsAppSenderApp extends StatelessWidget {
  const WhatsAppSenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EfforTrak Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF128C7E)),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}
