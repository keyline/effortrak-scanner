import 'package:flutter/services.dart';

class TitleCaseFormatter extends TextInputFormatter {
  const TitleCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var startOfWord = true;
    final result = StringBuffer();
    for (final rune in newValue.text.runes) {
      final character = String.fromCharCode(rune);
      if (RegExp(r'[A-Za-z]').hasMatch(character)) {
        result.write(startOfWord ? character.toUpperCase() : character);
        startOfWord = false;
      } else {
        result.write(character);
        startOfWord =
            character.trim().isEmpty || character == '-' || character == "'";
      }
    }
    return newValue.copyWith(text: result.toString());
  }
}
