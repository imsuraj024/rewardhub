import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';

void main() {
  group('RecentActivityModel.fromJson', () {
    test('positive: parses a full credit payload', () {
      final model = RecentActivityModel.fromJson({
        'id': 't1',
        'type': 'credit',
        'points': 50,
        'date': '2024-01-15T10:30:00.000Z',
      });

      expect(model.id, 't1');
      expect(model.type, 'credit');
      expect(model.points, 50);
      expect(model.date, DateTime.parse('2024-01-15T10:30:00.000Z'));
      expect(model.isCredit, isTrue);
    });

    test('positive: numeric id is coerced to string', () {
      final model = RecentActivityModel.fromJson({
        'id': 99,
        'type': 'debit',
        'points': 10,
        'date': '2024-01-01',
      });

      expect(model.id, '99');
    });

    test('positive: points given as a double is truncated to int', () {
      final model = RecentActivityModel.fromJson({
        'id': '1',
        'type': 'credit',
        'points': 12.7,
        'date': '2024-01-01',
      });

      expect(model.points, 12);
    });

    test('negative: debit type is not credit', () {
      final model = RecentActivityModel.fromJson({
        'id': '1',
        'type': 'debit',
        'points': 5,
        'date': '2024-01-01',
      });

      expect(model.isCredit, isFalse);
    });

    test('edge: missing fields fall back to safe defaults', () {
      final model = RecentActivityModel.fromJson(<String, dynamic>{});

      expect(model.id, '');
      expect(model.type, '');
      expect(model.points, 0);
      expect(model.date, DateTime(1970));
      expect(model.isCredit, isFalse);
    });

    test('edge: unparseable date falls back to epoch sentinel', () {
      final model = RecentActivityModel.fromJson({
        'id': '1',
        'type': 'credit',
        'points': 1,
        'date': 'not-a-date',
      });

      expect(model.date, DateTime(1970));
    });

    test('edge: isCredit is case-insensitive', () {
      final model = RecentActivityModel.fromJson({
        'id': '1',
        'type': 'CREDIT',
        'points': 1,
        'date': '2024-01-01',
      });

      expect(model.isCredit, isTrue);
    });

    test('edge: Debit with capital D is parsed correctly as debit', () {
      final model = RecentActivityModel.fromJson({
        'id': '3',
        'type': 'Debit',
        'points': 4,
        'date': '2026-07-18T14:16:56.457',
      });

      expect(model.isCredit, isFalse);
      expect(model.isDebit, isTrue);
    });

    test('edge: null values fall back to defaults', () {
      final model = RecentActivityModel.fromJson({
        'id': null,
        'type': null,
        'points': null,
        'date': null,
      });

      expect(model.id, '');
      expect(model.type, '');
      expect(model.points, 0);
      expect(model.date, DateTime(1970));
    });
  });
}
