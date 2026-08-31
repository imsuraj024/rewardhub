import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/qr_scan/data/models/qr_scan_response_model.dart';

void main() {
  group('QrScanResponseModel.fromJson', () {
    test('positive: parses PascalCase keys', () {
      final model = QrScanResponseModel.fromJson({
        'Success': true,
        'Message': 'awarded',
        'PointsEarned': 25,
      });

      expect(model.success, isTrue);
      expect(model.message, 'awarded');
      expect(model.pointsEarned, 25);
    });

    test('positive: parses camelCase keys', () {
      final model = QrScanResponseModel.fromJson({
        'success': true,
        'message': 'ok',
        'pointsEarned': 10,
      });

      expect(model.success, isTrue);
      expect(model.message, 'ok');
      expect(model.pointsEarned, 10);
    });

    test('negative: failure is preserved with message and no points', () {
      final model = QrScanResponseModel.fromJson({
        'Success': false,
        'Message': 'already scanned',
      });

      expect(model.success, isFalse);
      expect(model.message, 'already scanned');
      expect(model.pointsEarned, isNull);
    });

    test('edge: missing fields fall back to safe defaults', () {
      final model = QrScanResponseModel.fromJson(<String, dynamic>{});

      expect(model.success, isFalse);
      expect(model.message, isNull);
      expect(model.pointsEarned, isNull);
    });

    test('edge: PascalCase takes precedence over camelCase', () {
      final model = QrScanResponseModel.fromJson({
        'Success': true,
        'success': false,
        'PointsEarned': 7,
        'pointsEarned': 3,
      });

      expect(model.success, isTrue);
      expect(model.pointsEarned, 7);
    });

    test('edge: null values fall back to defaults', () {
      final model = QrScanResponseModel.fromJson({
        'Success': null,
        'Message': null,
        'PointsEarned': null,
      });

      expect(model.success, isFalse);
      expect(model.message, isNull);
      expect(model.pointsEarned, isNull);
    });
  });
}
