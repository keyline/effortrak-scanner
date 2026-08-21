import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/app_input_decoration.dart';
import '../../widgets/contact_saved_animation.dart';
import '../../widgets/title_case_formatter.dart';
import '../create_contact/create_contact_page.dart';
import '../contacts/duplicate_contact_guard.dart';
import '../create_contact/contact_card_share.dart';
import '../templates/whatsapp_templates.dart';
import 'business_card_parser.dart';

class ScanCardPage extends StatefulWidget {
  const ScanCardPage({super.key});

  @override
  State<ScanCardPage> createState() => _ScanCardPageState();
}

class _ScanCardPageState extends State<ScanCardPage>
    with WidgetsBindingObserver {
  static const _defaultWhatsAppMessage = 'Hi.';
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _previewKey = GlobalKey();
  final _previewTransform = TransformationController();
  XFile? _image;
  CameraController? _camera;
  CameraDescription? _backCamera;
  bool _startingCamera = false;
  bool _processing = false;
  bool _hasResult = false;
  bool _saveToContacts = true;
  bool _sendWhatsApp = false;
  bool _sendMyContact = false;
  bool _saving = false;
  ContactCardData? _myCard;
  String? _selectedMessage;
  List<String> _messages = const [
    'Hello, I wanted to contact you regarding your request.',
    'Hi, please let me know when you are available.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _loadMyCard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startCamera();
    });
  }

  Future<void> _loadMyCard() async {
    final card = await ContactCardData.load();
    if (mounted) setState(() => _myCard = card);
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(savedWhatsAppTemplatesKey);
    if (stored != null && mounted) setState(() => _messages = stored);
  }

  Future<void> _startCamera() async {
    if (_startingCamera || _processing) return;
    setState(() => _startingCamera = true);
    try {
      final cameras = await availableCameras();
      _backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      await _camera?.dispose();
      final controller = CameraController(
        _backCamera!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _camera = controller;
      await controller.initialize();
      if (mounted) {
        setState(() {
          _image = null;
          _hasResult = false;
        });
      }
    } on CameraException catch (error) {
      _message(
        error.code == 'CameraAccessDenied'
            ? 'Allow camera access in phone settings to scan a card.'
            : 'Camera could not start. Please try again.',
      );
    } catch (_) {
      _message('No camera is available on this device.');
    } finally {
      if (mounted) setState(() => _startingCamera = false);
    }
  }

  Future<void> _captureCard() async {
    final camera = _camera;
    if (camera == null ||
        !camera.value.isInitialized ||
        camera.value.isTakingPicture) {
      return;
    }
    try {
      final fullImage = await camera.takePicture();
      final cardImage = await _cropCapturedCard(fullImage);
      await _recognize(cardImage);
    } catch (_) {
      _message('Could not capture the card. Hold steady and try again.');
    }
  }

  Future<XFile> _cropCapturedCard(XFile source) async {
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    final previewBox =
        _previewKey.currentContext?.findRenderObject() as RenderBox?;
    if (decoded == null || previewBox == null) return source;

    // CameraPreview uses BoxFit.cover. Map the visible guide rectangle back to
    // the actual sensor image, then save only that card-shaped region.
    final oriented = img.bakeOrientation(decoded);
    final displayWidth = previewBox.size.width;
    final displayHeight = previewBox.size.height;
    const inset = 18.0;
    final scale =
        (displayWidth / oriented.width) > (displayHeight / oriented.height)
        ? displayWidth / oriented.width
        : displayHeight / oriented.height;
    final renderedWidth = oriented.width * scale;
    final renderedHeight = oriented.height * scale;
    final hiddenX = (renderedWidth - displayWidth) / 2;
    final hiddenY = (renderedHeight - displayHeight) / 2;

    final x = ((hiddenX + inset) / scale).round().clamp(0, oriented.width - 1);
    final y = ((hiddenY + inset) / scale).round().clamp(0, oriented.height - 1);
    final width = ((displayWidth - inset * 2) / scale).round().clamp(
      1,
      oriented.width - x,
    );
    final height = ((displayHeight - inset * 2) / scale).round().clamp(
      1,
      oriented.height - y,
    );
    final cropped = img.copyCrop(
      oriented,
      x: x,
      y: y,
      width: width,
      height: height,
    );
    final outputPath = '${source.path}_card.jpg';
    await File(outputPath).writeAsBytes(img.encodeJpg(cropped, quality: 94));
    return XFile(outputPath);
  }

  void _retake() {
    _previewTransform.value = Matrix4.identity();
    setState(() {
      _image = null;
      _hasResult = false;
      _saveToContacts = true;
      _sendWhatsApp = false;
      _sendMyContact = false;
      _selectedMessage = null;
      _name.clear();
      _company.clear();
      _mobile.clear();
      _email.clear();
      _address.clear();
    });
    if (_camera?.value.isInitialized != true) _startCamera();
  }

  Future<void> _pickGallery() async {
    XFile? image;
    try {
      image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 2200,
      );
    } catch (_) {
      _message('Gallery could not open. Allow photo access in phone settings.');
      return;
    }
    if (image == null || !mounted) return;
    await _recognize(image);
  }

  Future<void> _recognize(XFile image) async {
    setState(() {
      _image = image;
      _processing = true;
      _hasResult = false;
    });

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final ocrImage = await _createOcrInputImage(image);
      final normalResult = await recognizer.processImage(
        InputImage.fromFilePath(ocrImage.path),
      );
      final normalText = normalResult.text.trim();
      final firstPassCard = normalText.isEmpty
          ? const BusinessCardData()
          : BusinessCardParser.parse(normalText);
      final needsFallback =
          firstPassCard.name.trim().isEmpty ||
          firstPassCard.mobile.replaceAll(RegExp(r'\D'), '').length < 7;
      final enhancedImage = needsFallback
          ? await _createOcrEnhancedImage(ocrImage)
          : null;
      final enhancedResult = enhancedImage == null
          ? null
          : await recognizer.processImage(
              InputImage.fromFilePath(enhancedImage.path),
            );
      final recognizedText = <String>{
        if (normalText.isNotEmpty) normalText,
        if (enhancedResult?.text.trim().isNotEmpty == true)
          enhancedResult!.text.trim(),
      }.join('\n');
      if (recognizedText.isEmpty) {
        _message(
          'No readable text found. Keep handwriting clear, close and well lit.',
        );
        return;
      }
      final card = BusinessCardParser.parse(recognizedText);
      _name.text = card.name;
      _company.text = card.company;
      _mobile.text = card.mobile;
      _email.text = card.email;
      _address.text = card.address;
      if (mounted) setState(() => _hasResult = true);
    } catch (_) {
      _message('The card could not be read. Try again in better light.');
    } finally {
      await recognizer.close();
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<XFile> _createOcrInputImage(XFile source) async {
    try {
      final decoded = img.decodeImage(await source.readAsBytes());
      if (decoded == null) return source;
      final oriented = img.bakeOrientation(decoded);
      const maxDimension = 1600;
      if (oriented.width <= maxDimension && oriented.height <= maxDimension) {
        return source;
      }
      final resized = oriented.width >= oriented.height
          ? img.copyResize(
              oriented,
              width: maxDimension,
              interpolation: img.Interpolation.linear,
            )
          : img.copyResize(
              oriented,
              height: maxDimension,
              interpolation: img.Interpolation.linear,
            );
      final path = '${source.path}_ocr_input.jpg';
      await File(path).writeAsBytes(img.encodeJpg(resized, quality: 90));
      return XFile(path);
    } catch (_) {
      return source;
    }
  }

  Future<XFile?> _createOcrEnhancedImage(XFile source) async {
    try {
      final decoded = img.decodeImage(await source.readAsBytes());
      if (decoded == null) return null;
      var enhanced = img.bakeOrientation(decoded);
      enhanced = img.grayscale(enhanced);
      enhanced = img.adjustColor(enhanced, contrast: 1.42, brightness: 1.06);
      enhanced = img.convolution(
        enhanced,
        filter: const [0, -1, 0, -1, 5, -1, 0, -1, 0],
        amount: .72,
      );
      final path = '${source.path}_ocr_enhanced.jpg';
      await File(path).writeAsBytes(img.encodeJpg(enhanced, quality: 96));
      return XFile(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_saveToContacts && !_sendWhatsApp && !_sendMyContact) {
      _message('Select at least one action to continue.');
      return;
    }
    final normalizedPhone = _normalizePhone(_mobile.text);
    final digits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
    if ((_saveToContacts && _name.text.trim().isEmpty) || digits.length < 10) {
      _message('Please check the name and mobile number.');
      return;
    }
    setState(() => _saving = true);
    try {
      if (_saveToContacts) {
        final status = await FlutterContacts.permissions.request(
          PermissionType.readWrite,
        );
        if (status != PermissionStatus.granted) {
          _message('Contacts permission is required to save this contact.');
          return;
        }
        final duplicate = await findDuplicateContact(normalizedPhone);
        if (duplicate != null && mounted) {
          final saveAnyway = await confirmSaveDuplicate(context, duplicate);
          if (!saveAnyway) return;
        }
        await FlutterContacts.create(
          Contact(
            name: Name(first: _name.text.trim()),
            phones: [Phone(number: normalizedPhone)],
            emails: _email.text.trim().isEmpty
                ? []
                : [Email(address: _email.text.trim())],
            organizations: _company.text.trim().isEmpty
                ? []
                : [Organization(name: _company.text.trim())],
            addresses: _address.text.trim().isEmpty
                ? []
                : [
                    Address(
                      formatted: _address.text.trim(),
                      street: _address.text.trim(),
                    ),
                  ],
          ),
        );
      }
      if (_saveToContacts && mounted) {
        await showContactSavedAnimation(context);
      }
      if (_sendMyContact && _myCard != null && mounted) {
        final template = _selectedMessage?.trim().isNotEmpty == true
            ? _selectedMessage!.trim()
            : _defaultWhatsAppMessage;
        final card = _myCard!;
        _retake();
        await shareContactAsVcf(card, message: _sendWhatsApp ? template : null);
      } else if (_sendWhatsApp && mounted) {
        final message = _selectedMessage?.trim().isNotEmpty == true
            ? _selectedMessage!.trim()
            : _defaultWhatsAppMessage;
        _retake();
        final opened = await _openWhatsApp(digits, message);
        if (!opened) _message('WhatsApp could not be opened on this phone.');
      } else if (_saveToContacts && mounted) {
        _retake();
      }
    } catch (_) {
      _message('Unable to save the contact. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _openWhatsApp(String digits, String message) async {
    final uri = Uri.parse(
      'whatsapp://send?phone=$digits&text=${Uri.encodeComponent(message)}',
    );
    if (Platform.isAndroid) {
      for (final package in const ['com.whatsapp', 'com.whatsapp.w4b']) {
        try {
          await AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: uri.toString(),
            package: package,
          ).launch();
          return true;
        } catch (_) {}
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
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  String _normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) digits = '91$digits';
    return digits.isEmpty ? '' : '+$digits';
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _previewTransform.dispose();
    for (final controller in [_name, _company, _mobile, _email, _address]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      camera.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed && _backCamera != null) {
      _startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071B18),
      appBar: AppBar(
        title: const Text(
          'Scan a business card',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF071B18),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          children: [
            ClipRRect(
              key: _previewKey,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 210,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B3F38),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _image != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          InteractiveViewer(
                            transformationController: _previewTransform,
                            panEnabled: true,
                            scaleEnabled: true,
                            minScale: 1,
                            maxScale: 8,
                            boundaryMargin: const EdgeInsets.all(120),
                            clipBehavior: Clip.hardEdge,
                            child: Image.file(
                              File(_image!.path),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: FilledButton.tonalIcon(
                              onPressed: _processing ? null : _retake,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.black.withValues(
                                  alpha: .62,
                                ),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Retake'),
                            ),
                          ),
                          if (_processing)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.46),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Color(0xFF25D366),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Reading card…',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : _camera?.value.isInitialized == true
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _camera!.value.previewSize!.height,
                              height: _camera!.value.previewSize!.width,
                              child: CameraPreview(_camera!),
                            ),
                          ),
                          const _CameraFrame(),
                        ],
                      )
                    : _startingCamera
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF25D366),
                        ),
                      )
                    : const _ScannerGuide(),
              ),
            ),
            if (_hasResult) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .07),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Review detected details',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      _name,
                      'Name',
                      Icons.person_outline,
                      titleCase: true,
                    ),
                    _field(_company, 'Company name', Icons.business_outlined),
                    _field(
                      _mobile,
                      'Mobile number',
                      Icons.phone_outlined,
                      phone: true,
                    ),
                    _field(_email, 'Email', Icons.email_outlined),
                    _field(
                      _address,
                      'Address',
                      Icons.location_on_outlined,
                      lines: 2,
                    ),
                    if (_sendWhatsApp) ...[
                      const SizedBox(height: 2),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMessage,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        decoration: appInputDecoration(
                          label: 'WhatsApp template',
                          hint: 'Select a saved message',
                          icon: Icons.chat_outlined,
                        ),
                        items:
                            <String>[
                                  _defaultWhatsAppMessage,
                                  ..._messages.where(
                                    (message) =>
                                        message != _defaultWhatsAppMessage,
                                  ),
                                ]
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
                        onChanged: (value) =>
                            setState(() => _selectedMessage = value),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF071B18),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: SafeArea(
          top: false,
          child: _hasResult
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2924),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF315A52)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionCheckbox(
                              label: 'Save contact',
                              icon: Icons.person_add_alt_1_rounded,
                              value: _saveToContacts,
                              enabled: !_saving,
                              onChanged: (value) =>
                                  setState(() => _saveToContacts = value),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: _ActionCheckbox(
                              label: 'WhatsApp',
                              icon: Icons.chat_rounded,
                              value: _sendWhatsApp,
                              enabled: !_saving,
                              onChanged: (value) => setState(() {
                                _sendWhatsApp = value;
                                if (value) {
                                  _selectedMessage ??= _defaultWhatsAppMessage;
                                }
                              }),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: _ActionCheckbox(
                              label: 'My contact',
                              icon: Icons.badge_outlined,
                              value: _sendMyContact,
                              enabled: !_saving && _myCard != null,
                              onChanged: (value) =>
                                  setState(() => _sendMyContact = value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed:
                            _saving ||
                                (!_saveToContacts &&
                                    !_sendWhatsApp &&
                                    !_sendMyContact)
                            ? null
                            : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: const Color(0xFF052E27),
                          disabledBackgroundColor: const Color(0xFF315A52),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF052E27),
                                ),
                              )
                            : const Icon(Icons.arrow_forward_rounded, size: 21),
                        label: _saving
                            ? const Text('Working…')
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 58,
                      child: OutlinedButton(
                        onPressed: _processing ? null : _pickGallery,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF52736D)),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 22),
                            SizedBox(height: 2),
                            Text('Gallery', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 58,
                        child: FilledButton.icon(
                          onPressed: _processing || _startingCamera
                              ? null
                              : (_camera?.value.isInitialized == true
                                    ? _captureCard
                                    : _startCamera),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: const Color(0xFF052E27),
                            disabledBackgroundColor: const Color(0xFF315A52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: Icon(
                            _camera?.value.isInitialized == true
                                ? Icons.camera
                                : Icons.camera_alt_rounded,
                            size: 25,
                          ),
                          label: Text(
                            'Scan card',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool phone = false,
    bool titleCase = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        autocorrect: false,
        enableSuggestions: false,
        maxLines: lines,
        textCapitalization: titleCase
            ? TextCapitalization.words
            : TextCapitalization.sentences,
        inputFormatters: titleCase ? const [TitleCaseFormatter()] : null,
        style: titleCase
            ? const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)
            : null,
        keyboardType: phone ? TextInputType.phone : TextInputType.text,
        decoration: appInputDecoration(label: label, hint: label, icon: icon),
      ),
    );
  }
}

class _ScannerGuide extends StatelessWidget {
  const _ScannerGuide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF62E58A), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_rounded,
              color: Color(0xFF62E58A),
              size: 46,
            ),
            SizedBox(height: 9),
            Text(
              'Place the entire card inside the frame',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Use a flat surface with good lighting',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCheckbox extends StatelessWidget {
  const _ActionCheckbox({
    required this.label,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF103E36) : const Color(0xFF0A2924),
          border: Border.all(
            color: value ? const Color(0xFF25D366) : const Color(0xFF52736D),
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: Checkbox(
                    value: value,
                    onChanged: enabled
                        ? (checked) => onChanged(checked ?? false)
                        : null,
                    activeColor: const Color(0xFF62D673),
                    checkColor: const Color(0xFF052E27),
                    side: const BorderSide(color: Colors.white70),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  icon,
                  color: enabled ? Colors.white70 : Colors.white30,
                  size: 17,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white38,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraFrame extends StatelessWidget {
  const _CameraFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF62E58A), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .52),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Keep all four corners inside the frame',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}
