import 'package:flutter/services.dart';

/// A [TextInputFormatter] that allows only digits (0-9).
class DigitsOnlyFormatter extends TextInputFormatter {
  /// Creates a formatter that allows only digits.
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // The previous value of the text field.
    TextEditingValue newValue, // The new value of the text field.
  ) {
    // If the new value is empty, allow it.
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Use a regular expression to remove all non-digit characters.
    final String newText = newValue.text.replaceAll(RegExp(r'\D'), '');

    // If the new value is different from the old one, update the text field.
    if (newText != newValue.text) {
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    // Otherwise, return the new value as is.
    return newValue;
  }
}
