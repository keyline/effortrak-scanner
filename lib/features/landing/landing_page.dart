import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../create_contact/create_contact_page.dart';
import '../home/home_page.dart';
import '../scan/scan_card_page.dart';
import '../templates/manage_templates_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  ContactCardData? _contactCard;

  @override
  void initState() {
    super.initState();
    _loadContactCard();
  }

  Future<void> _loadContactCard() async {
    final data = await ContactCardData.load();
    if (mounted) setState(() => _contactCard = data);
  }

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    await _loadContactCard();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                children: [
                  const Text(
                    'EfforTrak Scanner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF075E54),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
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
                        const Text(
                          'Add a new contact',
                          style: TextStyle(
                            color: Color(0xFF153D36),
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scan a visiting card or enter the details yourself.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LandingAction(
                          title: 'Scan a card',
                          subtitle: 'Capture details from a visiting card',
                          icon: Icons.document_scanner_rounded,
                          primary: true,
                          onTap: () => _open(context, const ScanCardPage()),
                        ),
                        const SizedBox(height: 9),
                        _LandingAction(
                          title: 'Add manually',
                          subtitle: 'Enter a contact and message',
                          icon: Icons.person_add_alt_1_rounded,
                          onTap: () => _open(context, const HomePage()),
                        ),
                        if (_contactCard == null) ...[
                          const SizedBox(height: 9),
                          _LandingAction(
                            title: 'Create your contact',
                            subtitle: 'Make your own shareable contact card',
                            icon: Icons.badge_outlined,
                            onTap: () =>
                                _open(context, const CreateContactPage()),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_contactCard case final card?) ...[
                    const SizedBox(height: 14),
                    _ContactQrCard(
                      data: card,
                      onEdit: () =>
                          _open(context, CreateContactPage(initialData: card)),
                    ),
                  ],
                  TextButton.icon(
                    onPressed: () =>
                        _open(context, const ManageTemplatesPage()),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF075E54),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 17),
                    label: const Text('Manage WhatsApp templates'),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Quick, simple and saved on your device',
                    style: TextStyle(
                      color: Color(0xFF41675F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _AppVersionLabel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactQrCard extends StatelessWidget {
  const _ContactQrCard({required this.data, required this.onEdit});

  final ContactCardData data;
  final VoidCallback onEdit;

  String get _vCard => buildContactVCard(
    name: data.name,
    phone: data.phone,
    alternatePhone: data.alternatePhone,
    email: data.email,
    website: data.website,
    facebook: data.facebook,
    instagram: data.instagram,
    linkedIn: data.linkedIn,
    bio: data.bio,
  );

  void _openFullScreenQr(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullScreenContactQr(name: data.name, vCard: _vCard),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF063D35).withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            data.name,
            style: const TextStyle(
              color: Color(0xFF153D36),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scan to add this contact',
            style: TextStyle(color: Color(0xFF5F7D76), fontSize: 12),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onDoubleTap: () => _openFullScreenQr(context),
            child: Container(
              key: const ValueKey('contact-qr-preview'),
              width: 190,
              height: 190,
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: _vCard,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    padding: EdgeInsets.zero,
                    eyeStyle: const QrEyeStyle(color: Color(0xFF075E54)),
                    dataModuleStyle: const QrDataModuleStyle(
                      color: Color(0xFF075E54),
                    ),
                  ),
                  _QrCenterLogo(size: 42),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Double-tap QR to enlarge',
            style: TextStyle(color: Color(0xFF78918B), fontSize: 10),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF128C7E),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Edit your contact'),
          ),
        ],
      ),
    );
  }
}

class _FullScreenContactQr extends StatelessWidget {
  const _FullScreenContactQr({required this.name, required this.vCard});

  final String name;
  final String vCard;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final qrSize = (screen.width - 42).clamp(240.0, 520.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF04110F),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 52,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Scan to add this contact',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        key: const ValueKey('full-screen-contact-qr'),
                        width: qrSize,
                        height: qrSize,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF25D366,
                              ).withValues(alpha: .16),
                              blurRadius: 38,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            QrImageView(
                              data: vCard,
                              version: QrVersions.auto,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                              padding: EdgeInsets.zero,
                              eyeStyle: const QrEyeStyle(
                                color: Color(0xFF052E27),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                color: Color(0xFF052E27),
                              ),
                            ),
                            _QrCenterLogo(
                              size: (qrSize * .20).clamp(52.0, 84.0).toDouble(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Double-tap anywhere to close',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .10),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrCenterLogo extends StatelessWidget {
  const _QrCenterLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('qr-center-logo'),
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .08),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .16),
      ),
      child: SvgPicture.asset(
        'assets/qr_contact_logo.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _AppVersionLabel extends StatefulWidget {
  const _AppVersionLabel();

  @override
  State<_AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<_AppVersionLabel> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final version = snapshot.data?.version;
        return SizedBox(
          height: 15,
          child: version == null
              ? null
              : Text(
                  'Version $version',
                  style: const TextStyle(
                    color: Color(0xFF5F7D76),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        );
      },
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
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: primary ? null : Border.all(color: const Color(0xFFB9DFC5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.78),
                        fontSize: 11,
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
