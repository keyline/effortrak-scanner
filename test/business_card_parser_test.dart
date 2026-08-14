import 'package:flutter_test/flutter_test.dart';
import 'package:whats_app/features/scan/business_card_parser.dart';

void main() {
  test('extracts core fields from an Indian business card', () {
    final card = BusinessCardParser.parse('''
Pritam Dutta
Keyline Digitech Pvt. Ltd.
+91 98765 43210
pritam@keylines.net
45/2 Manik Bandyopadhyay Sarani, Kolkata, West Bengal 700040
''');

    expect(card.name, 'Pritam Dutta');
    expect(card.company, 'Keyline Digitech Pvt. Ltd.');
    expect(card.mobile, '+91 98765 43210');
    expect(card.email, 'pritam@keylines.net');
    expect(card.address, contains('Kolkata'));
  });

  test('ignores logos and service headings when choosing a person name', () {
    final card = BusinessCardParser.parse('''
S.
Shilpi Rai
+91-99325 77778
+91-99324 77778
Ward No. 39
Haiderpara Bazar, Siliguri-1
sameeradvertising08 @ gmail. com
www.sameeradvertisingandit.com
OUR SERVICE
ADVERTISING
Outdoor Advertising
''');

    expect(card.name, 'Shilpi Rai');
    expect(card.company, 'Sameer Advertising And It');
    expect(card.mobile, '+91-99325 77778');
    expect(card.email, 'sameeradvertising08@gmail.com');
    expect(card.address, contains('Haiderpara Bazar'));
  });

  test('separates a named director from the company', () {
    final card = BusinessCardParser.parse('''
Nigam Soni (Director)
SiliconLine Systems Pvt. Ltd.
Software Development & Consultancy House
134-C, Sarat Bose Road, 2nd Floor, Kolkata - 700 029
Cell: 98300-54567 Office No.: 98302-92224
E.mail: mail@siliconlinesystems.com
''');

    expect(card.name, 'Nigam Soni');
    expect(card.company, 'SiliconLine Systems Pvt. Ltd.');
    expect(card.mobile, contains('98300-54567'));
    expect(card.email, 'mail@siliconlinesystems.com');
  });
}
