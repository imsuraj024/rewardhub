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
