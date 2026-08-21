import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'create_contact_page.dart';

Future<void> shareContactAsVcf(ContactCardData card, {String? message}) async {
  final vCard = buildContactVCard(
    name: card.name,
    phone: card.phone,
    alternatePhone: card.alternatePhone,
    email: card.email,
    website: card.website,
    facebook: card.facebook,
    instagram: card.instagram,
    linkedIn: card.linkedIn,
    bio: card.bio,
  );
  final safeName = card.name
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final fileName = '${safeName.isEmpty ? 'contact' : safeName}.vcf';
  final file = XFile.fromData(
    Uint8List.fromList(utf8.encode(vCard)),
    mimeType: 'text/vcard',
    name: fileName,
  );

  await SharePlus.instance.share(
    ShareParams(
      files: [file],
      fileNameOverrides: [fileName],
      text: message?.trim().isNotEmpty == true ? message!.trim() : null,
      subject: '${card.name} — contact card',
    ),
  );
}
