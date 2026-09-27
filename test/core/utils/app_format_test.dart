import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/utils/app_format.dart';

void main() {
  group('AppFormat.points', () {
    test('positive: uses Indian digit grouping', () {
      expect(AppFormat.points(12345678), '1,23,45,678');
      expect(AppFormat.points(100000), '1,00,000');
    });

    test('edge: small numbers stay ungrouped', () {
      expect(AppFormat.points(0), '0');
      expect(AppFormat.points(999), '999');
    });
  });

  group('AppFormat.pointsWithUnit', () {
    test('positive: singular for exactly one point', () {
      expect(AppFormat.pointsWithUnit(1), '1 point');
    });

    test('positive: plural otherwise, with grouping', () {
      expect(AppFormat.pointsWithUnit(0), '0 points');
      expect(AppFormat.pointsWithUnit(1500), '1,500 points');
    });
  });

  group('AppFormat.signedPoints', () {
    test('positive: credits get a plus sign', () {
      expect(AppFormat.signedPoints(50, isCredit: true), '+50 points');
    });

    test('positive: debits get a true minus sign (U+2212)', () {
      expect(AppFormat.signedPoints(1000, isCredit: false), '−1,000 points');
      expect(
        AppFormat.signedPoints(1, isCredit: false).codeUnitAt(0),
        0x2212,
      );
    });
  });

  group('AppFormat.dateTime', () {
    test('positive: day, short month and 12-hour time', () {
      expect(
        AppFormat.dateTime(DateTime(2026, 9, 27, 15, 15)),
        '27 Sep, 3:15 PM',
      );
    });

    test('edge: morning times and single-digit days', () {
      expect(AppFormat.dateTime(DateTime(2026, 1, 5, 9, 5)), '5 Jan, 9:05 AM');
    });
  });
}
