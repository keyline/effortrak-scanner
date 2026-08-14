import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../scan/scan_card_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/whatsapp.png', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.72),
                  const Color(0xFFF1FFF7).withValues(alpha: 0.88),
                  const Color(0xFF075E54).withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              child: Column(
                children: [
                  const Text(
                    'EfforTrak Scanner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF075E54),
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF063D35,
                          ).withValues(alpha: 0.16),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 68,
                          width: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F8EC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.contact_page_rounded,
                            color: Color(0xFF128C7E),
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Add a new contact',
                          style: TextStyle(
                            color: Color(0xFF153D36),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Scan a visiting card or enter the details yourself.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _LandingAction(
                          title: 'Scan a card',
                          subtitle: 'Capture details from a visiting card',
                          icon: Icons.document_scanner_rounded,
                          primary: true,
                          onTap: () => _open(context, const ScanCardPage()),
                        ),
                        const SizedBox(height: 12),
                        _LandingAction(
                          title: 'Add manually',
                          subtitle: 'Enter a number and prepare your message',
                          icon: Icons.person_add_alt_1_rounded,
                          onTap: () => _open(context, const HomePage()),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Quick, simple and saved on your device',
                    style: TextStyle(
                      color: Color(0xFF41675F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingAction extends StatelessWidget {
  const _LandingAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final Color foreground = primary ? Colors.white : const Color(0xFF075E54);

    return Material(
      color: primary ? const Color(0xFF25D366) : const Color(0xFFF5FCF7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: primary ? null : Border.all(color: const Color(0xFFB9DFC5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 27),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: foreground,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
