import 'package:flutter/services.dart';

/// Formats a 10-digit Indian phone number as "XXXXX XXXXX".
/// Automatically inserts a space after the 5th digit.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip everything except digits
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Cap at 10 digits
    final capped = digits.length > 10 ? digits.substring(0, 10) : digits;

    // Build formatted string: "XXXXX XXXXX"
    final buffer = StringBuffer();
    for (int i = 0; i < capped.length; i++) {
      if (i == 5) buffer.write(' ');
      buffer.write(capped[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
