import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/auth/data/models/otp_response_model.dart';

void main() {
  group('OtpResponseModel.fromJson', () {
    test('positive: parses PascalCase keys', () {
      final model = OtpResponseModel.fromJson({
        'Success': true,
        'Message': 'verified',
      });

      expect(model.success, isTrue);
      expect(model.message, 'verified');
    });

    test('positive: parses camelCase keys', () {
      final model = OtpResponseModel.fromJson({
        'success': true,
        'message': 'ok',
      });

      expect(model.success, isTrue);
      expect(model.message, 'ok');
    });

    test('negative: success=false is preserved with message', () {
      final model = OtpResponseModel.fromJson({
        'Success': false,
        'Message': 'invalid otp',
      });

      expect(model.success, isFalse);
      expect(model.message, 'invalid otp');
    });

    test('edge: missing fields fall back to safe defaults', () {
      final model = OtpResponseModel.fromJson(<String, dynamic>{});

      expect(model.success, isFalse);
      expect(model.message, isNull);
    });

    test('edge: PascalCase takes precedence over camelCase', () {
      final model = OtpResponseModel.fromJson({
        'Success': true,
        'success': false,
        'Message': 'pascal',
        'message': 'camel',
      });

      expect(model.success, isTrue);
      expect(model.message, 'pascal');
    });

    test('edge: null values fall back to defaults', () {
      final model = OtpResponseModel.fromJson({
        'Success': null,
        'Message': null,
      });

      expect(model.success, isFalse);
      expect(model.message, isNull);
    });
  });
}
