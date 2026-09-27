/// Reusable form validators for payment / bank related fields.
///
/// Each validator returns `null` when the input is valid, or an error
/// message string otherwise — matching the signature expected by
/// [FormFieldValidator] used across `TextFormField`s.
///
/// All fields here are optional: an empty value passes validation. To make
/// a field required, wrap the validator or add a required check beforehand.
class PaymentValidators {
  PaymentValidators._();

  // UPI handle, e.g. "name@okhdfcbank". Local part allows alphanumerics,
  // dots, hyphens and underscores; the handle (PSP) is alphabetic.
  static final RegExp _upiId = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');

  // IFSC: 4 letters + 0 + 6 alphanumerics (RBI format), e.g. "SBIN0001234".
  static final RegExp _ifsc = RegExp(r'^[A-Za-z]{4}0[A-Za-z0-9]{6}$');

  /// Validates a UPI ID (`name@bank`) or a 10-digit Google Pay mobile number.
  ///
  /// Empty input passes unless [required] is set, in which case it returns a
  /// "required" message.
  static String? upiOrGooglePay(String? value, {bool required = false}) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return required ? 'Enter your UPI ID or Google Pay number' : null;
    }

    // Google Pay is linked to a mobile number — accept a plain 10-digit number.
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (!input.contains('@')) {
      if (RegExp(r'^\d[\d ]*$').hasMatch(input)) {
        if (digits.length != 10) {
          return 'Enter a valid 10-digit Google Pay number';
        }
        return null;
      }
    }

    if (!_upiId.hasMatch(input)) {
      return 'Enter a valid UPI ID (e.g. name@okhdfcbank) or Google Pay number';
    }
    return null;
  }

  /// Validates a bank account number (9–18 digits, as used by Indian banks).
  ///
  /// Optional — returns `null` for empty input.
  static String? accountNumber(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;

    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length != input.length) {
      return 'Account number can contain digits only';
    }
    if (digits.length < 9 || digits.length > 18) {
      return 'Enter a valid account number (9–18 digits)';
    }
    return null;
  }

  /// Validates an IFSC code (RBI format: `AAAA0XXXXXX`).
  ///
  /// Optional — returns `null` for empty input.
  static String? ifscCode(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;

    if (!_ifsc.hasMatch(input)) {
      return 'Enter a valid IFSC code (e.g. SBIN0001234)';
    }
    return null;
  }
}
