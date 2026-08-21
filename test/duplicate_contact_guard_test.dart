import 'package:flutter_test/flutter_test.dart';
import 'package:whats_app/features/contacts/duplicate_contact_guard.dart';

void main() {
  test('matches local and country-code versions of the same phone', () {
    expect(phoneNumbersMatch('+91 93301 09091', '9330109091'), isTrue);
  });

  test('ignores spacing and punctuation', () {
    expect(phoneNumbersMatch('(033) 4000-5000', '03340005000'), isTrue);
  });

  test('does not match different or too-short phone numbers', () {
    expect(phoneNumbersMatch('9330109091', '9330109092'), isFalse);
    expect(phoneNumbersMatch('12345', '12345'), isFalse);
  });
}
