import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/wallet/data/models/raise_request_response_model.dart';

void main() {
  group('RaiseRequestResponseModel.fromJson', () {
    test('positive: parses PascalCase keys', () {
      final model = RaiseRequestResponseModel.fromJson({
        'Success': true,
        'Message': 'request raised',
      });

      expect(model.success, isTrue);
      expect(model.message, 'request raised');
    });

    test('positive: parses camelCase keys', () {
      final model = RaiseRequestResponseModel.fromJson({
        'success': true,
        'message': 'ok',
      });

      expect(model.success, isTrue);
      expect(model.message, 'ok');
    });

    test('negative: failure is preserved with message', () {
      final model = RaiseRequestResponseModel.fromJson({
        'Success': false,
        'Message': 'insufficient balance',
      });

      expect(model.success, isFalse);
      expect(model.message, 'insufficient balance');
    });

    test('edge: missing fields fall back to safe defaults', () {
      final model = RaiseRequestResponseModel.fromJson(<String, dynamic>{});

      expect(model.success, isFalse);
      expect(model.message, isNull);
    });

    test('edge: PascalCase takes precedence over camelCase', () {
      final model = RaiseRequestResponseModel.fromJson({
        'Success': true,
        'success': false,
        'Message': 'pascal',
        'message': 'camel',
      });

      expect(model.success, isTrue);
      expect(model.message, 'pascal');
    });

    test('edge: null values fall back to defaults', () {
      final model = RaiseRequestResponseModel.fromJson({
        'Success': null,
        'Message': null,
      });

      expect(model.success, isFalse);
      expect(model.message, isNull);
    });
  });
}
