import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/auth/data/models/register_response_model.dart';

void main() {
  group('RegisterResponseModel.fromJson', () {
    test('positive: parses PascalCase keys', () {
      final model = RegisterResponseModel.fromJson({
        'Success': true,
        'Token': 'jwt-token',
        'Message': 'registered',
      });

      expect(model.success, isTrue);
      expect(model.token, 'jwt-token');
      expect(model.message, 'registered');
    });

    test('positive: parses camelCase keys', () {
      final model = RegisterResponseModel.fromJson({
        'success': true,
        'token': 'abc',
        'message': 'ok',
      });

      expect(model.success, isTrue);
      expect(model.token, 'abc');
      expect(model.message, 'ok');
    });

    test('negative: failure without token is preserved', () {
      final model = RegisterResponseModel.fromJson({
        'Success': false,
        'Message': 'already exists',
      });

      expect(model.success, isFalse);
      expect(model.token, isNull);
      expect(model.message, 'already exists');
    });

    test('edge: missing fields fall back to safe defaults', () {
      final model = RegisterResponseModel.fromJson(<String, dynamic>{});

      expect(model.success, isFalse);
      expect(model.token, isNull);
      expect(model.message, isNull);
    });

    test('edge: PascalCase takes precedence over camelCase', () {
      final model = RegisterResponseModel.fromJson({
        'Success': true,
        'success': false,
        'Token': 'pascal',
        'token': 'camel',
      });

      expect(model.success, isTrue);
      expect(model.token, 'pascal');
    });

    test('edge: null values fall back to defaults', () {
      final model = RegisterResponseModel.fromJson({
        'Success': null,
        'Token': null,
        'Message': null,
      });

      expect(model.success, isFalse);
      expect(model.token, isNull);
      expect(model.message, isNull);
    });
  });
}
