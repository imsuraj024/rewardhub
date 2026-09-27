import 'package:flutter/services.dart';

/// Formats a 10-digit Indian phone number as "XXXXX XXXXX".
/// Automatically inserts a space after the 5th digit.
///
/// Pasted or autofilled numbers are normalised: a leading "+91"/"91" on a
/// 12-digit number or a leading "0" on an 11-digit number is dropped. The
/// cursor stays where the user was typing instead of jumping to the end.
class PhoneInputFormatter extends TextInputFormatter {
  static final RegExp _nonDigit = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    var digits = text.replaceAll(_nonDigit, '');

    // Drop a country or trunk prefix from pasted / autofilled numbers.
    var dropped = 0;
    if (digits.length == 12 && digits.startsWith('91')) {
      dropped = 2;
    } else if (digits.length == 11 && digits.startsWith('0')) {
      dropped = 1;
    }
    digits = digits.substring(dropped);

    // Cap at 10 digits
    final capped = digits.length > 10 ? digits.substring(0, 10) : digits;

    // Build formatted string: "XXXXX XXXXX"
    final buffer = StringBuffer();
    for (int i = 0; i < capped.length; i++) {
      if (i == 5) buffer.write(' ');
      buffer.write(capped[i]);
    }

    final formatted = buffer.toString();

    // Keep the cursor after the same digit it followed before formatting.
    final end = newValue.selection.end;
    final selectionEnd = end >= 0 && end <= text.length ? end : text.length;
    final digitsBefore = text
        .substring(0, selectionEnd)
        .replaceAll(_nonDigit, '')
        .length;
    final before = (digitsBefore - dropped).clamp(0, capped.length);
    final offset = before + (before > 5 ? 1 : 0);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
