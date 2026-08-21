import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

String comparablePhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

bool phoneNumbersMatch(String first, String second) {
  final a = comparablePhone(first);
  final b = comparablePhone(second);
  return a.length >= 7 && a == b;
}

Future<Contact?> findDuplicateContact(String phone) async {
  final contacts = await FlutterContacts.getAll(
    properties: const {ContactProperty.name, ContactProperty.phone},
  );
  for (final contact in contacts) {
    if (contact.phones.any((saved) => phoneNumbersMatch(saved.number, phone))) {
      return contact;
    }
  }
  return null;
}

Future<bool> confirmSaveDuplicate(
  BuildContext context,
  Contact duplicate,
) async {
  final displayName = duplicate.displayName?.trim() ?? '';
  final firstName = duplicate.name?.first?.trim() ?? '';
  final name = displayName.isNotEmpty
      ? displayName
      : firstName.isNotEmpty
      ? firstName
      : 'An existing contact';
  final number = duplicate.phones.isEmpty
      ? ''
      : duplicate.phones.first.number.trim();

  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.content_copy_rounded,
            color: Color(0xFFE49B22),
          ),
          title: const Text('Contact already exists'),
          content: Text(
            number.isEmpty
                ? '$name is already saved on this phone. Do you want to save another copy?'
                : '$name is already saved with $number. Do you want to save another copy?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save anyway'),
            ),
          ],
        ),
      ) ??
      false;
}
