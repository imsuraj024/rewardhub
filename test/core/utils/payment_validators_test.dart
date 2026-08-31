import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/utils/payment_validators.dart';

void main() {
  group('PaymentValidators.upiOrGooglePay', () {
    test('accepts a well-formed UPI id', () {
      expect(PaymentValidators.upiOrGooglePay('name@okhdfcbank'), isNull);
      expect(PaymentValidators.upiOrGooglePay('john.doe-1@ybl'), isNull);
    });

    test('accepts a 10-digit Google Pay number', () {
      expect(PaymentValidators.upiOrGooglePay('9876543210'), isNull);
      expect(PaymentValidators.upiOrGooglePay('98765 43210'), isNull);
    });

    test('rejects a number that is not 10 digits', () {
      expect(PaymentValidators.upiOrGooglePay('98765'), isNotNull);
      expect(PaymentValidators.upiOrGooglePay('987654321012'), isNotNull);
    });

    test('rejects a malformed UPI id', () {
      expect(PaymentValidators.upiOrGooglePay('name@123'), isNotNull);
      expect(PaymentValidators.upiOrGooglePay('@okhdfcbank'), isNotNull);
    });

    test('empty passes unless required', () {
      expect(PaymentValidators.upiOrGooglePay(''), isNull);
      expect(PaymentValidators.upiOrGooglePay(null), isNull);
      expect(PaymentValidators.upiOrGooglePay('', required: true), isNotNull);
    });

    test('trims surrounding whitespace', () {
      expect(PaymentValidators.upiOrGooglePay('  name@okhdfcbank  '), isNull);
    });
  });

  group('PaymentValidators.accountNumber', () {
    test('accepts 9 to 18 digits', () {
      expect(PaymentValidators.accountNumber('123456789'), isNull);
      expect(PaymentValidators.accountNumber('123456789012345678'), isNull);
    });

    test('rejects too short or too long', () {
      expect(PaymentValidators.accountNumber('12345678'), isNotNull);
      expect(PaymentValidators.accountNumber('1234567890123456789'), isNotNull);
    });

    test('rejects non-digit characters', () {
      expect(PaymentValidators.accountNumber('12345678a'), isNotNull);
    });

    test('empty passes (optional)', () {
      expect(PaymentValidators.accountNumber(''), isNull);
      expect(PaymentValidators.accountNumber(null), isNull);
    });
  });

  group('PaymentValidators.ifscCode', () {
    test('accepts a valid IFSC', () {
      expect(PaymentValidators.ifscCode('SBIN0001234'), isNull);
    });

    test('rejects an invalid IFSC', () {
      expect(PaymentValidators.ifscCode('SBIN1001234'), isNotNull);
      expect(PaymentValidators.ifscCode('SBI0001234'), isNotNull);
    });

    test('empty passes (optional)', () {
      expect(PaymentValidators.ifscCode(''), isNull);
      expect(PaymentValidators.ifscCode(null), isNull);
    });
  });
}
