import 'package:flutter/material.dart';

import '../features/home/home_page.dart';

class WhatsAppSenderApp extends StatelessWidget {
  const WhatsAppSenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WhatsApp Sender',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF128C7E),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
