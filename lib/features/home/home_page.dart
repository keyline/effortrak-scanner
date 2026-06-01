import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/app_input_decoration.dart';
import '../../widgets/message_mode_button.dart';
import '../../widgets/section_title.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String savedMessagesKey = 'saved_quick_sms';
  final TextEditingController numberController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController customSmsController = TextEditingController();
  bool showQuickMessage = true;
  String? selectedQuickMessage;
  List<String> savedMessages = <String>[
    'Hello, I wanted to contact you regarding your request.',
    'Hi, please let me know when you are available.',
  ];

  @override
  void initState() {
    super.initState();
    loadSavedMessages();
  }

  Future<void> loadSavedMessages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? storedMessages = prefs.getStringList(savedMessagesKey);

    if (storedMessages == null || !mounted) {
      return;
    }

    setState(() {
      savedMessages = storedMessages;
    });
  }

  Future<void> saveMessagesToPhone() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(savedMessagesKey, savedMessages);
  }

  Future<void> sendMessage() async {
    final String number = numberController.text.trim();
    final String message = showQuickMessage
        ? selectedQuickMessage?.trim() ?? ''
        : messageController.text.trim();

    if (number.isEmpty || number.length < 10) {
      showSnackBar('Please enter a valid phone number');
      return;
    }

    if (showQuickMessage) {
      if (message.isEmpty) {
        showSnackBar('Please choose a quick message');
        return;
      }
    } else if (message.isEmpty) {
      showSnackBar('Please type a message first');
      return;
    }

    final Uri url = Uri.parse(
      'https://wa.me/91$number?text=${Uri.encodeComponent(message)}',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      showSnackBar('Could not open WhatsApp');
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF075E54),
      ),
    );
  }

  Future<void> saveCustomSms() async {
    final String message = customSmsController.text.trim();

    if (message.isEmpty) {
      showSnackBar('Type a custom SMS before saving');
      return;
    }

    if (savedMessages.contains(message)) {
      showSnackBar('This message is already saved');
      return;
    }

    setState(() {
      savedMessages.insert(0, message);
    });

    await saveMessagesToPhone();
    customSmsController.clear();
    showSnackBar('Quick SMS saved');
  }

  void chooseQuickMessage(String? message) {
    if (message == null) {
      return;
    }

    setState(() {
      selectedQuickMessage = message;
      messageController.text = message;
      messageController.selection = TextSelection.collapsed(
        offset: message.length,
      );
    });
  }

  Future<void> deleteSavedMessage(int index) async {
    setState(() {
      savedMessages.removeAt(index);
      if (selectedQuickMessage != null &&
          !savedMessages.contains(selectedQuickMessage)) {
        selectedQuickMessage = null;
        messageController.clear();
      }
    });

    await saveMessagesToPhone();
    showSnackBar('Saved message removed');
  }

  Future<void> confirmDeleteSavedMessage(
    BuildContext dialogContext,
    int index,
    VoidCallback refreshDialog,
  ) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: dialogContext,
      builder: (alertContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'Delete quick message?',
            style: TextStyle(
              color: Color(0xFF064E45),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This message will be removed from your saved options.',
            style: TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(alertContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF075E54)),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(alertContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await deleteSavedMessage(index);
    refreshDialog();
  }

  void selectMessageMode(bool quickMessage) {
    setState(() {
      showQuickMessage = quickMessage;
    });
  }

  Future<void> showManageQuickMessages() async {
    customSmsController.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: const Text(
                'Manage Quick Messages',
                style: TextStyle(
                  color: Color(0xFF064E45),
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (savedMessages.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6FFFA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFF25D366).withValues(alpha: 0.26),
                            ),
                          ),
                          child: Text(
                            'No quick messages saved.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: savedMessages.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final String savedMessage = savedMessages[index];

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6FFFA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF25D366,
                                  ).withValues(alpha: 0.26),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.sms_rounded,
                                    color: Color(0xFF128C7E),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      savedMessage,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF163D35),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete Message',
                                    onPressed: () async {
                                      await confirmDeleteSavedMessage(
                                        dialogContext,
                                        index,
                                        () => dialogSetState(() {}),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFF075E54),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: customSmsController,
                        maxLines: 3,
                        decoration: appInputDecoration(
                          label: 'New Quick Message',
                          hint: 'Write a reusable message here',
                          icon: Icons.bookmark_add_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await saveCustomSms();
                            dialogSetState(() {});
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Message'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Color(0xFF075E54)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    numberController.dispose();
    messageController.dispose();
    customSmsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/logo.svg',
          height: 50,
          fit: BoxFit.contain,
        ),
      ),
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
                  Colors.white.withValues(alpha: 0.2),
                  const Color(0xFF25D366).withValues(alpha: 0.04),
                  const Color(0xFF075E54).withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF063D35,
                          ).withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 54,
                              width: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF25D366,
                                    ).withValues(alpha: 0.26),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Direct WhatsApp',
                                    style: TextStyle(
                                      color: Color(0xFF064E45),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Save templates or type a custom SMS.',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const SectionTitle(
                          icon: Icons.phone_rounded,
                          title: 'Receiver Number',
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: numberController,
                          keyboardType: TextInputType.phone,
                          decoration: appInputDecoration(
                            label: 'Phone Number',
                            hint: 'Enter 10-digit number',
                            icon: Icons.phone_rounded,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const SectionTitle(
                          icon: Icons.tune_rounded,
                          title: 'Message Type',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: MessageModeButton(
                                label: 'Quick Message',
                                icon: Icons.flash_on_rounded,
                                selected: showQuickMessage,
                                onTap: () => selectMessageMode(true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MessageModeButton(
                                label: 'Custom Message',
                                icon: Icons.edit_note_rounded,
                                selected: !showQuickMessage,
                                onTap: () => selectMessageMode(false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!showQuickMessage)
                          TextField(
                            controller: messageController,
                            maxLines: 5,
                            decoration: appInputDecoration(
                              label: 'Custom Message',
                              hint: 'Type your message and send',
                              icon: Icons.message_rounded,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1FFF7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFF25D366,
                                ).withValues(alpha: 0.42),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionTitle(
                                  icon: Icons.auto_awesome_rounded,
                                  title: 'Quick Message',
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: selectedQuickMessage,
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: const Color(0xFF128C7E),
                                  isExpanded: true,
                                  decoration: appInputDecoration(
                                    label: 'Choose Message',
                                    hint: 'Select a saved quick message',
                                    icon: Icons.sms_rounded,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF163D35),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: savedMessages
                                      .map(
                                        (message) => DropdownMenuItem<String>(
                                          value: message,
                                          child: Text(
                                            message,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: chooseQuickMessage,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: showManageQuickMessages,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF075E54),
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Color(0xFF25D366),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.tune_rounded),
                                    label: const Text('Manage Quick Messages'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: sendMessage,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF25D366,
                              ).withValues(alpha: 0.34),
                            ),
                            icon: const Icon(Icons.send_rounded),
                            label: const Text(
                              'Open WhatsApp',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF075E54).withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your message opens in WhatsApp before sending.',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
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
