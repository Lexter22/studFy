import 'package:flutter/services.dart';

/// Forces text input to uppercase as the user types.
///
/// Use for fields that must always be uppercase (course codes like BSIT,
/// sections, registration/class codes, instructor IDs, etc.):
///
///   TextField(
///     textCapitalization: TextCapitalization.characters,
///     inputFormatters: const [UpperCaseTextFormatter()],
///   )
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return TextEditingValue(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
