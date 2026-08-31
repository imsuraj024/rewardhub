import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/auth/data/models/login_response_model.dart';

void main() {
  group('LoginResponseModel.fromJson', () {
    test('parses PascalCase keys', () {
      final model = LoginResponseModel.fromJson({
        'Success': true,
        'Message': 'ok',
        'IsNewUser': true,
        'Token': 'abc',
      });

      expect(model.success, isTrue);
      expect(model.message, 'ok');
      expect(model.isNewUser, isTrue);
      expect(model.token, 'abc');
    });

    test('parses camelCase keys', () {
      final model = LoginResponseModel.fromJson({
        'success': true,
        'message': 'ok',
        'isNewUser': false,
        'token': 'xyz',
      });

      expect(model.success, isTrue);
      expect(model.isNewUser, isFalse);
      expect(model.token, 'xyz');
    });

    test('falls back to safe defaults for missing fields', () {
      final model = LoginResponseModel.fromJson(<String, dynamic>{});

      expect(model.success, isFalse);
      expect(model.isNewUser, isFalse);
      expect(model.message, isNull);
      expect(model.token, isNull);
    });
  });
}
