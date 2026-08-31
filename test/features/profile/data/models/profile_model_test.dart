import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';

void main() {
  group('ProfileModel.fromJson', () {
    test('positive: parses a full payload', () {
      final model = ProfileModel.fromJson({
        'id': 'u1',
        'name': 'Alice',
        'mobile': '9876543210',
        'points': 150,
      });

      expect(model.id, 'u1');
      expect(model.name, 'Alice');
      expect(model.mobile, '9876543210');
      expect(model.points, 150);
    });

    test('positive: parses profile payload with bank details', () {
      final model = ProfileModel.fromJson({
        'id': '10',
        'name': 'ROhit',
        'mobile': '9167360660',
        'points': 8,
        'bankName': 'NA',
        'bankAddress': 'NA',
        'ifscCode': 'NA',
        'accountNumber': 'NA',
        'upiId': '8657221204@ybl',
      });

      expect(model.id, '10');
      expect(model.name, 'ROhit');
      expect(model.mobile, '9167360660');
      expect(model.points, 8);
      expect(model.bankName, 'NA');
      expect(model.bankAddress, 'NA');
      expect(model.ifscCode, 'NA');
      expect(model.accountNumber, 'NA');
      expect(model.upiId, '8657221204@ybl');
    });

    test('positive: numeric id is coerced to string', () {
      final model = ProfileModel.fromJson({
        'id': 42,
        'name': 'Bob',
        'mobile': '1',
        'points': 10,
      });

      expect(model.id, '42');
    });

    test('positive: points given as a double is truncated to int', () {
      final model = ProfileModel.fromJson({
        'id': '1',
        'name': 'C',
        'mobile': '2',
        'points': 99.9,
      });

      expect(model.points, 99);
    });

    test('negative: missing fields fall back to empty/zero defaults', () {
      final model = ProfileModel.fromJson(<String, dynamic>{});

      expect(model.id, '');
      expect(model.name, '');
      expect(model.mobile, '');
      expect(model.points, 0);
    });

    test('edge: null values fall back to defaults', () {
      final model = ProfileModel.fromJson({
        'id': null,
        'name': null,
        'mobile': null,
        'points': null,
      });

      expect(model.id, '');
      expect(model.name, '');
      expect(model.mobile, '');
      expect(model.points, 0);
    });

    test('edge: negative points are preserved', () {
      final model = ProfileModel.fromJson({
        'id': '1',
        'name': 'N',
        'mobile': '2',
        'points': -5,
      });

      expect(model.points, -5);
    });
  });

  group('ProfileModel.toJson', () {
    test('positive: serializes all fields', () {
      final model = ProfileModel(
        id: 'u1',
        name: 'Alice',
        mobile: '9876543210',
        points: 150,
      );

      expect(model.toJson(), {
        'id': 'u1',
        'name': 'Alice',
        'mobile': '9876543210',
        'points': 150,
      });
    });

    test('edge: round-trips through fromJson', () {
      final original = ProfileModel(
        id: 'x',
        name: 'Y',
        mobile: 'z',
        points: 7,
      );

      final roundTripped = ProfileModel.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.name, original.name);
      expect(roundTripped.mobile, original.mobile);
      expect(roundTripped.points, original.points);
    });
  });
}
