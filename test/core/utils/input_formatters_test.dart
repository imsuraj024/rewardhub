import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/utils/phone_input_formatter.dart';
import 'package:rewardhub/core/utils/text_input_formatters.dart';

TextEditingValue _value(String text) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

void main() {
  group('PhoneInputFormatter', () {
    final formatter = PhoneInputFormatter();

    TextEditingValue format(String input) =>
        formatter.formatEditUpdate(TextEditingValue.empty, _value(input));

    test('inserts a space after the fifth digit', () {
      expect(format('9876543210').text, '98765 43210');
    });

    test('strips non-digit characters', () {
      expect(format('98a76-54!32 10').text, '98765 43210');
    });

    test('caps input at 10 digits', () {
      expect(format('987654321099').text, '98765 43210');
    });

    test('leaves fewer than six digits unspaced', () {
      expect(format('98765').text, '98765');
      expect(format('987').text, '987');
    });

    test('drops a +91 country code from pasted or autofilled numbers', () {
      expect(format('+91 98765 43210').text, '98765 43210');
      expect(format('919876543210').text, '98765 43210');
    });

    test('drops a leading trunk 0 from an 11-digit number', () {
      expect(format('09876543210').text, '98765 43210');
    });

    test('keeps the cursor after the digit being typed', () {
      final result = formatter.formatEditUpdate(
        _value('98765 43210'),
        const TextEditingValue(
          text: '987765 43210',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(result.text, '98776 54321');
      expect(result.selection, const TextSelection.collapsed(offset: 3));
    });

    test('puts the cursor past the space once it follows the sixth digit', () {
      final result = formatter.formatEditUpdate(
        _value('98765'),
        const TextEditingValue(
          text: '987654',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(result.text, '98765 4');
      expect(result.selection.baseOffset, 7);
    });

    test('an invalid selection falls back to the end', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '9876543210',
          selection: TextSelection.collapsed(offset: -1),
        ),
      );
      expect(result.selection.baseOffset, 11);
    });
  });

  group('CapitalizeFirstLetterFormatter', () {
    final formatter = CapitalizeFirstLetterFormatter();

    TextEditingValue format(String input) =>
        formatter.formatEditUpdate(TextEditingValue.empty, _value(input));

    test('capitalizes the first letter', () {
      expect(format('john').text, 'John');
    });

    test('leaves empty input untouched', () {
      expect(format('').text, '');
    });
  });

  group('UpperCaseTextFormatter', () {
    final formatter = UpperCaseTextFormatter();

    test('uppercases the entire input', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        _value('sbin0001234'),
      );
      expect(result.text, 'SBIN0001234');
    });
  });
}
