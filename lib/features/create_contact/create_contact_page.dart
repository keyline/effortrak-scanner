import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/app_input_decoration.dart';
import '../../widgets/contact_saved_animation.dart';
import '../../widgets/title_case_formatter.dart';
import '../contacts/duplicate_contact_guard.dart';

class CreateContactPage extends StatefulWidget {
  const CreateContactPage({super.key, this.initialData});

  final ContactCardData? initialData;

  @override
  State<CreateContactPage> createState() => _CreateContactPageState();
}

class _CreateContactPageState extends State<CreateContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _bioController = TextEditingController();
  bool _saving = false;

  List<TextEditingController> get _controllers => [
    _nameController,
    _phoneController,
    _alternatePhoneController,
    _emailController,
    _websiteController,
    _facebookController,
    _instagramController,
    _linkedInController,
    _bioController,
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      _applyData(data);
      _recoverMissingNativeFields(data);
    }
  }

  void _applyData(ContactCardData data) {
    _nameController.text = data.name;
    _phoneController.text = data.phone;
    _alternatePhoneController.text = data.alternatePhone;
    _emailController.text = data.email;
    _websiteController.text = data.website;
    _facebookController.text = data.facebook;
    _instagramController.text = data.instagram;
    _linkedInController.text = data.linkedIn;
    _bioController.text = data.bio;
  }

  Future<void> _recoverMissingNativeFields(ContactCardData saved) async {
    final id = saved.contactId;
    if (id == null) return;
    try {
      final hasPermission = await FlutterContacts.permissions.has(
        PermissionType.readWrite,
      );
      if (!hasPermission) return;
      final contact = await FlutterContacts.get(
        id,
        properties: ContactProperties.allProperties,
      );
      if (contact == null || !mounted) return;

      String websiteWithLabel(String label) {
        for (final website in contact.websites) {
          if (website.label.customLabel?.toLowerCase() == label.toLowerCase()) {
            return website.url;
          }
        }
        return '';
      }

      final recovered = ContactCardData(
        contactId: id,
        name: saved.name,
        phone: saved.phone,
        alternatePhone: saved.alternatePhone.isNotEmpty
            ? saved.alternatePhone
            : contact.phones.length > 1
            ? contact.phones[1].number
            : '',
        email: saved.email.isNotEmpty
            ? saved.email
            : contact.emails.firstOrNull?.address ?? '',
        website: saved.website.isNotEmpty
            ? saved.website
            : contact.websites
                      .where((item) => item.label.customLabel == null)
                      .firstOrNull
                      ?.url ??
                  '',
        facebook: saved.facebook.isNotEmpty
            ? saved.facebook
            : websiteWithLabel('Facebook'),
        instagram: saved.instagram.isNotEmpty
            ? saved.instagram
            : websiteWithLabel('Instagram'),
        linkedIn: saved.linkedIn.isNotEmpty
            ? saved.linkedIn
            : websiteWithLabel('LinkedIn'),
        bio: saved.bio.isNotEmpty
            ? saved.bio
            : contact.notes.firstOrNull?.note ?? '',
      );
      _applyData(recovered);
      await recovered.save();
    } catch (_) {
      // Keep the locally saved values if native contact recovery is unavailable.
    }
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  String? _phoneValidator(String? value, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Phone number is required.' : null;
    if (text.replaceAll(RegExp(r'\D'), '').length < 7) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final permission = await FlutterContacts.permissions.request(
        PermissionType.readWrite,
      );
      if (permission != PermissionStatus.granted) {
        _showMessage('Contacts permission is required to save your card.');
        return;
      }

      final data = ContactCardData(
        contactId: widget.initialData?.contactId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        alternatePhone: _alternatePhoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        facebook: _facebookController.text.trim(),
        instagram: _instagramController.text.trim(),
        linkedIn: _linkedInController.text.trim(),
        bio: _bioController.text.trim(),
      );
      final newCard = buildContactCard(
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
      String contactId;
      final oldId = data.contactId;
      final oldContact = oldId == null
          ? null
          : await FlutterContacts.get(oldId);
      if (oldContact == null) {
        final duplicate = await findDuplicateContact(data.phone);
        if (duplicate != null && mounted) {
          final saveAnyway = await confirmSaveDuplicate(context, duplicate);
          if (!saveAnyway) return;
        }
        contactId = await FlutterContacts.create(newCard);
      } else {
        await FlutterContacts.update(
          oldContact.copyWith(
            name: newCard.name,
            phones: newCard.phones,
            emails: newCard.emails,
            websites: newCard.websites,
            notes: newCard.notes,
          ),
        );
        contactId = oldId!;
      }
      await data.copyWith(contactId: contactId).save();

      if (!mounted) return;
      await showContactSavedAnimation(context);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      _showMessage('Unable to save your contact card. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialData == null
              ? 'Create your contact'
              : 'Edit your contact',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        foregroundColor: const Color(0xFF075E54),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _field(
              controller: _nameController,
              label: 'Name *',
              hint: 'Your full name',
              icon: Icons.person_outline_rounded,
              capitalization: TextCapitalization.words,
              formatters: const [TitleCaseFormatter()],
              validator: (value) => _requiredText(value, 'Name'),
            ),
            _field(
              controller: _phoneController,
              label: 'Phone number *',
              hint: 'Your primary phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) => _phoneValidator(value, required: true),
            ),
            _field(
              controller: _alternatePhoneController,
              label: 'Alternate contact number',
              hint: 'Optional second number',
              icon: Icons.phone_forwarded_outlined,
              keyboardType: TextInputType.phone,
              validator: _phoneValidator,
            ),
            _field(
              controller: _emailController,
              label: 'Email',
              hint: 'name@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            _field(
              controller: _websiteController,
              label: 'Website',
              hint: 'https://yourwebsite.com',
              icon: Icons.language_rounded,
              keyboardType: TextInputType.url,
            ),
            _field(
              controller: _facebookController,
              label: 'Facebook',
              hint: 'Profile link or username',
              icon: Icons.facebook_rounded,
              keyboardType: TextInputType.url,
            ),
            _field(
              controller: _instagramController,
              label: 'Instagram',
              hint: 'Profile link or username',
              icon: Icons.camera_alt_outlined,
              keyboardType: TextInputType.url,
            ),
            _field(
              controller: _linkedInController,
              label: 'LinkedIn',
              hint: 'Profile link or username',
              icon: Icons.work_outline_rounded,
              keyboardType: TextInputType.url,
            ),
            _field(
              controller: _bioController,
              label: 'Short bio',
              hint: 'A few words about you',
              icon: Icons.notes_rounded,
              capitalization: TextCapitalization.sentences,
              maxLines: 3,
              maxLength: 240,
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_alt_rounded),
                label: Text(_saving ? 'Saving...' : 'Save to phone'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        inputFormatters: formatters,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        textInputAction: maxLines == 1
            ? TextInputAction.next
            : TextInputAction.newline,
        decoration: appInputDecoration(label: label, hint: hint, icon: icon)
            .copyWith(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
            ),
      ),
    );
  }
}

class ContactCardData {
  static const storageKey = 'my_contact_card';

  const ContactCardData({
    this.contactId,
    required this.name,
    required this.phone,
    this.alternatePhone = '',
    this.email = '',
    this.website = '',
    this.facebook = '',
    this.instagram = '',
    this.linkedIn = '',
    this.bio = '',
  });

  final String? contactId;
  final String name;
  final String phone;
  final String alternatePhone;
  final String email;
  final String website;
  final String facebook;
  final String instagram;
  final String linkedIn;
  final String bio;

  ContactCardData copyWith({String? contactId}) => ContactCardData(
    contactId: contactId ?? this.contactId,
    name: name,
    phone: phone,
    alternatePhone: alternatePhone,
    email: email,
    website: website,
    facebook: facebook,
    instagram: instagram,
    linkedIn: linkedIn,
    bio: bio,
  );

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(toJson()));
  }

  static Future<ContactCardData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return null;
    return ContactCardData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
    'contactId': contactId,
    'name': name,
    'phone': phone,
    'alternatePhone': alternatePhone,
    'email': email,
    'website': website,
    'facebook': facebook,
    'instagram': instagram,
    'linkedIn': linkedIn,
    'bio': bio,
  };

  factory ContactCardData.fromJson(Map<String, dynamic> json) =>
      ContactCardData(
        contactId: json['contactId'] as String?,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        alternatePhone: json['alternatePhone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        website: json['website'] as String? ?? '',
        facebook: json['facebook'] as String? ?? '',
        instagram: json['instagram'] as String? ?? '',
        linkedIn: json['linkedIn'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
      );
}

String buildContactVCard({
  required String name,
  required String phone,
  String alternatePhone = '',
  String email = '',
  String website = '',
  String facebook = '',
  String instagram = '',
  String linkedIn = '',
  String bio = '',
}) {
  String clean(String value) => value.trim();
  String escape(String value) => clean(value)
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\n', r'\n');

  final lines = <String>[
    'BEGIN:VCARD',
    'VERSION:3.0',
    'FN:${escape(name)}',
    'N:;${escape(name)};;;',
    'TEL;TYPE=CELL:${escape(phone)}',
    if (clean(alternatePhone).isNotEmpty)
      'TEL;TYPE=VOICE:${escape(alternatePhone)}',
    if (clean(email).isNotEmpty) 'EMAIL:${escape(email)}',
    if (clean(website).isNotEmpty) 'URL:${escape(website)}',
    if (clean(facebook).isNotEmpty)
      'X-SOCIALPROFILE;TYPE=facebook:${escape(facebook)}',
    if (clean(instagram).isNotEmpty)
      'X-SOCIALPROFILE;TYPE=instagram:${escape(instagram)}',
    if (clean(linkedIn).isNotEmpty)
      'X-SOCIALPROFILE;TYPE=linkedin:${escape(linkedIn)}',
    if (clean(bio).isNotEmpty) 'NOTE:${escape(bio)}',
    'END:VCARD',
  ];
  return lines.join('\r\n');
}

Contact buildContactCard({
  required String name,
  required String phone,
  String alternatePhone = '',
  String email = '',
  String website = '',
  String facebook = '',
  String instagram = '',
  String linkedIn = '',
  String bio = '',
}) {
  String clean(String value) => value.trim();
  final secondPhone = clean(alternatePhone);
  final emailAddress = clean(email);
  final site = clean(website);
  final socialProfiles = <({String label, String value})>[
    (label: 'Facebook', value: clean(facebook)),
    (label: 'Instagram', value: clean(instagram)),
    (label: 'LinkedIn', value: clean(linkedIn)),
  ].where((profile) => profile.value.isNotEmpty);

  return Contact(
    name: Name(first: clean(name)),
    phones: [
      Phone(number: clean(phone), isPrimary: true),
      if (secondPhone.isNotEmpty)
        Phone(
          number: secondPhone,
          label: const Label(PhoneLabel.custom, 'Alternate'),
        ),
    ],
    emails: [if (emailAddress.isNotEmpty) Email(address: emailAddress)],
    websites: [
      if (site.isNotEmpty) Website(url: site),
      ...socialProfiles.map(
        (profile) => Website(
          url: profile.value,
          label: Label(WebsiteLabel.custom, profile.label),
        ),
      ),
    ],
    notes: [if (clean(bio).isNotEmpty) Note(note: clean(bio))],
  );
}
