import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whats_app/features/create_contact/create_contact_page.dart';
import 'package:whats_app/features/home/home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a complete native contact card', () {
    final contact = buildContactCard(
      name: 'Asha Sen',
      phone: '+91 98765 43210',
      alternatePhone: '033 4000 5000',
      email: 'asha@example.com',
      website: 'https://example.com',
      facebook: 'https://facebook.com/asha',
      instagram: '@asha',
      linkedIn: 'https://linkedin.com/in/asha',
      bio: 'Product designer from Kolkata.',
    );

    expect(contact.name?.first, 'Asha Sen');
    expect(contact.phones, hasLength(2));
    expect(contact.emails.single.address, 'asha@example.com');
    expect(contact.websites, hasLength(4));
    expect(contact.notes.single.note, 'Product designer from Kolkata.');
    expect(
      contact.websites.last.label,
      const Label(WebsiteLabel.custom, 'LinkedIn'),
    );
  });

  test('omits all blank optional fields', () {
    final contact = buildContactCard(name: 'Asha Sen', phone: '9876543210');

    expect(contact.phones, hasLength(1));
    expect(contact.emails, isEmpty);
    expect(contact.websites, isEmpty);
    expect(contact.notes, isEmpty);
  });

  test('creates a scannable vCard payload with optional details', () {
    final vCard = buildContactVCard(
      name: 'Asha Sen',
      phone: '+91 98765 43210',
      email: 'asha@example.com',
      website: 'https://example.com',
      linkedIn: 'https://linkedin.com/in/asha',
      bio: 'Designer, Kolkata',
    );

    expect(vCard, startsWith('BEGIN:VCARD\r\nVERSION:3.0'));
    expect(vCard, contains('FN:Asha Sen'));
    expect(vCard, contains('TEL;TYPE=CELL:+91 98765 43210'));
    expect(vCard, contains('EMAIL:asha@example.com'));
    expect(vCard, contains(r'NOTE:Designer\, Kolkata'));
    expect(vCard, endsWith('END:VCARD'));
  });

  test('formats a saved card for a WhatsApp message', () {
    final message = formatContactCardMessage(
      const ContactCardData(
        name: 'Asha Sen',
        phone: '9876543210',
        email: 'asha@example.com',
      ),
    );

    expect(message, contains('My contact card'));
    expect(message, contains('Phone: 9876543210'));
    expect(message, contains('Email: asha@example.com'));
  });

  test('persists and reloads every editable contact-card field', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const original = ContactCardData(
      contactId: 'contact-1',
      name: 'Asha Sen',
      phone: '9876543210',
      alternatePhone: '03340005000',
      email: 'asha@example.com',
      website: 'https://example.com',
      facebook: 'https://facebook.com/asha',
      instagram: '@asha',
      linkedIn: 'https://linkedin.com/in/asha',
      bio: 'Product designer.',
    );
    await original.save();

    final restored = await ContactCardData.load();
    expect(restored?.alternatePhone, original.alternatePhone);
    expect(restored?.email, original.email);
    expect(restored?.website, original.website);
    expect(restored?.facebook, original.facebook);
    expect(restored?.instagram, original.instagram);
    expect(restored?.linkedIn, original.linkedIn);
    expect(restored?.bio, original.bio);
  });
}
