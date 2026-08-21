import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/app_input_decoration.dart';
import '../../widgets/contact_saved_animation.dart';
import '../../widgets/title_case_formatter.dart';
import '../create_contact/create_contact_page.dart';
import '../contacts/duplicate_contact_guard.dart';
import '../create_contact/contact_card_share.dart';
import '../templates/whatsapp_templates.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.initialName = '',
    this.initialPhone = '',
    this.whatsAppOnly = false,
  });

  final String initialName;
  final String initialPhone;
  final bool whatsAppOnly;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const defaultWhatsAppMessage = 'Hi.';
  final nameController = TextEditingController();
  final numberController = TextEditingController();
  bool sendWhatsApp = false;
  bool sendMyCard = false;
  bool saving = false;
  ContactCardData? myCard;
  String? selectedQuickMessage;
  List<String> savedMessages = List<String>.from(defaultWhatsAppTemplates);

  @override
  void initState() {
    super.initState();
    nameController.text = widget.initialName;
    numberController.text = widget.initialPhone;
    sendWhatsApp = widget.whatsAppOnly;
    if (sendWhatsApp) selectedQuickMessage = defaultWhatsAppMessage;
    _loadSavedMessages();
    _loadMyCard();
  }

  Future<void> _loadMyCard() async {
    final card = await ContactCardData.load();
    if (mounted) setState(() => myCard = card);
  }

  Future<void> _loadSavedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(savedWhatsAppTemplatesKey);
    if (stored != null && mounted) setState(() => savedMessages = stored);
  }

  Future<void> _createTemplate() async {
    final controller = TextEditingController();
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create new template',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Write a reusable WhatsApp message.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autocorrect: false,
              enableSuggestions: false,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: appInputDecoration(
                label: 'Message template',
                hint: 'Type your message…',
                icon: Icons.chat_outlined,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) Navigator.pop(sheetContext, value);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Save template'),
              ),
            ),
          ],
        ),
      ),
    );
    if (message == null || !mounted) return;
    final updated = <String>[
      message,
      ...savedMessages.where((m) => m != message),
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(savedWhatsAppTemplatesKey, updated);
    if (mounted) {
      setState(() {
        savedMessages = updated;
        selectedQuickMessage = message;
      });
      _showMessage('Template created and selected.');
    }
  }

  Future<void> _saveContact() async {
    final name = nameController.text.trim();
    final phone = numberController.text.trim();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (name.isEmpty) {
      return _showMessage('Please enter the contact name.');
    }
    if (digits.length < 10) {
      return _showMessage('Please enter a valid phone number.');
    }
    setState(() => saving = true);
    try {
      if (!widget.whatsAppOnly) {
        final permission = await FlutterContacts.permissions.request(
          PermissionType.readWrite,
        );
        if (permission != PermissionStatus.granted) {
          _showMessage('Contacts permission is required to save this contact.');
          return;
        }
        final duplicate = await findDuplicateContact(phone);
        if (duplicate != null && mounted) {
          final saveAnyway = await confirmSaveDuplicate(context, duplicate);
          if (!saveAnyway) return;
        }
        await FlutterContacts.create(
          Contact(
            name: Name(first: name),
            phones: <Phone>[Phone(number: phone)],
          ),
        );
        if (mounted) await showContactSavedAnimation(context);
      }

      if (sendMyCard && myCard != null) {
        final template = selectedQuickMessage?.trim().isNotEmpty == true
            ? selectedQuickMessage!.trim()
            : defaultWhatsAppMessage;
        await shareContactAsVcf(
          myCard!,
          message: sendWhatsApp ? template : null,
        );
      } else if (sendWhatsApp) {
        final message = selectedQuickMessage?.trim().isNotEmpty == true
            ? selectedQuickMessage!.trim()
            : defaultWhatsAppMessage;
        final opened = await _openWhatsApp(digits, message);
        if (!opened && mounted) {
          _showMessage('WhatsApp could not be opened on this phone.');
        }
      }
    } catch (_) {
      _showMessage(
        widget.whatsAppOnly
            ? 'WhatsApp could not be opened. Please check that it is installed.'
            : 'Unable to save the contact. Please try again.',
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<bool> _openWhatsApp(String digits, String message) async {
    final appUri = Uri.parse(
      'whatsapp://send?phone=$digits&text=${Uri.encodeComponent(message)}',
    );
    if (Platform.isAndroid) {
      for (final package in const ['com.whatsapp', 'com.whatsapp.w4b']) {
        try {
          await AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: appUri.toString(),
            package: package,
          ).launch();
          return true;
        } catch (_) {
          // Try WhatsApp Business when standard WhatsApp is unavailable.
        }
      }
      try {
        return await launchUrl(
          Uri.parse(
            'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
          ),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        return false;
      }
    }
    try {
      if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {
      // Some Android versions reject a custom scheme before trying its web
      // fallback, even when WhatsApp is installed.
    }

    final webUri = Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
    );
    try {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF075E54),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add contact manually',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        foregroundColor: const Color(0xFF075E54),
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/whatsapp.png', fit: BoxFit.cover),
          Container(color: Colors.white.withValues(alpha: 0.72)),
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF063D35).withValues(alpha: 0.13),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: const [TitleCaseFormatter()],
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: appInputDecoration(
                      label: 'Name',
                      hint: 'Contact name',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: numberController,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.phone,
                    decoration: appInputDecoration(
                      label: 'Phone number',
                      hint: 'Enter phone number',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactCheckbox(
                          label: 'Send message',
                          value: sendWhatsApp,
                          onChanged: widget.whatsAppOnly
                              ? null
                              : (value) => setState(() {
                                  sendWhatsApp = value;
                                  if (value) {
                                    selectedQuickMessage ??=
                                        defaultWhatsAppMessage;
                                  }
                                }),
                        ),
                      ),
                      Expanded(
                        child: _CompactCheckbox(
                          label: 'Send my card',
                          value: sendMyCard,
                          onChanged: myCard == null
                              ? null
                              : (value) => setState(() {
                                  sendMyCard = value;
                                }),
                        ),
                      ),
                    ],
                  ),
                  if (sendWhatsApp) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _createTemplate,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF128C7E),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New template'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedQuickMessage,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      decoration: appInputDecoration(
                        label: 'Quick message',
                        hint: 'Select a saved message',
                        icon: Icons.sms_outlined,
                      ),
                      items:
                          <String>[
                            defaultWhatsAppMessage,
                            ...savedMessages.where(
                              (message) => message != defaultWhatsAppMessage,
                            ),
                          ].map((message) {
                            return DropdownMenuItem<String>(
                              value: message,
                              child: Text(
                                message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (message) =>
                          setState(() => selectedQuickMessage = message),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: saving ? null : _saveContact,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        saving
                            ? 'Please wait...'
                            : widget.whatsAppOnly
                            ? 'Open WhatsApp'
                            : 'Save contact',
                      ),
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

class _CompactCheckbox extends StatelessWidget {
  const _CompactCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (checked) => onChanged!(checked ?? false),
              activeColor: const Color(0xFF25D366),
              visualDensity: VisualDensity.compact,
            ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: onChanged == null
                      ? Colors.grey
                      : const Color(0xFF153D36),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatContactCardMessage(ContactCardData card) {
  final lines = <String>[
    'My contact card',
    card.name,
    'Phone: ${card.phone}',
    if (card.alternatePhone.isNotEmpty) 'Alternate: ${card.alternatePhone}',
    if (card.email.isNotEmpty) 'Email: ${card.email}',
    if (card.website.isNotEmpty) 'Website: ${card.website}',
    if (card.facebook.isNotEmpty) 'Facebook: ${card.facebook}',
    if (card.instagram.isNotEmpty) 'Instagram: ${card.instagram}',
    if (card.linkedIn.isNotEmpty) 'LinkedIn: ${card.linkedIn}',
    if (card.bio.isNotEmpty) card.bio,
  ];
  return lines.join('\n');
}
