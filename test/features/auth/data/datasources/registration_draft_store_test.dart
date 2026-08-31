import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late RegistrationDraftStoreImpl store;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    store = RegistrationDraftStoreImpl();
  });

  group('RegistrationDraft model', () {
    test('positive: defaults are all empty strings', () {
      const d = RegistrationDraft();
      expect(d.name, '');
      expect(d.phone, '');
      expect(d.referral, '');
      expect(d.upi, '');
      expect(d.accountNumber, '');
      expect(d.ifsc, '');
      expect(d.aadhaarPath, '');
      expect(d.selfiePath, '');
    });

    test('positive: copyWith overrides only provided fields', () {
      const d = RegistrationDraft(name: 'A', phone: '1');
      final updated = d.copyWith(name: 'B', ifsc: 'IFSC0001');

      expect(updated.name, 'B');
      expect(updated.phone, '1');
      expect(updated.ifsc, 'IFSC0001');
    });

    test('edge: copyWith with no args returns equal field values', () {
      const d = RegistrationDraft(name: 'A', upi: 'a@b');
      final copy = d.copyWith();

      expect(copy.name, 'A');
      expect(copy.upi, 'a@b');
    });
  });

  group('read', () {
    test('edge: empty prefs yields an all-empty draft', () async {
      final draft = await store.read();

      expect(draft.name, '');
      expect(draft.phone, '');
      expect(draft.aadhaarPath, '');
    });

    test('positive: reads previously stored fields', () async {
      SharedPreferences.setMockInitialValues({
        'reg_draft_name': 'Suraj',
        'reg_draft_phone': '9876543210',
        'reg_draft_referral': 'REF1',
        'reg_draft_upi': 'suraj@upi',
        'reg_draft_account_number': '000123',
        'reg_draft_ifsc': 'HDFC0001',
        'reg_draft_aadhaar_path': '/a.png',
        'reg_draft_selfie_path': '/s.png',
      });

      final draft = await store.read();

      expect(draft.name, 'Suraj');
      expect(draft.phone, '9876543210');
      expect(draft.referral, 'REF1');
      expect(draft.upi, 'suraj@upi');
      expect(draft.accountNumber, '000123');
      expect(draft.ifsc, 'HDFC0001');
      expect(draft.aadhaarPath, '/a.png');
      expect(draft.selfiePath, '/s.png');
    });

    test('edge: partial data leaves other fields at defaults', () async {
      SharedPreferences.setMockInitialValues({
        'reg_draft_name': 'Only Name',
      });

      final draft = await store.read();

      expect(draft.name, 'Only Name');
      expect(draft.phone, '');
      expect(draft.upi, '');
    });
  });

  group('save', () {
    test('positive: persisted values are read back', () async {
      const draft = RegistrationDraft(
        name: 'Suraj',
        phone: '9876543210',
        referral: 'REF1',
        upi: 'suraj@upi',
        accountNumber: '000123',
        ifsc: 'HDFC0001',
        aadhaarPath: '/a.png',
        selfiePath: '/s.png',
      );

      await store.save(draft);
      final read = await store.read();

      expect(read.name, 'Suraj');
      expect(read.phone, '9876543210');
      expect(read.referral, 'REF1');
      expect(read.upi, 'suraj@upi');
      expect(read.accountNumber, '000123');
      expect(read.ifsc, 'HDFC0001');
      expect(read.aadhaarPath, '/a.png');
      expect(read.selfiePath, '/s.png');
    });

    test('edge: saving default draft round-trips empty strings', () async {
      await store.save(const RegistrationDraft());
      final read = await store.read();

      expect(read.name, '');
      expect(read.ifsc, '');
    });

    test('edge: re-saving overwrites previous values', () async {
      await store.save(const RegistrationDraft(name: 'Old'));
      await store.save(const RegistrationDraft(name: 'New'));

      final read = await store.read();
      expect(read.name, 'New');
    });
  });

  group('clear', () {
    test('positive: clears all stored fields', () async {
      await store.save(
        const RegistrationDraft(name: 'Suraj', phone: '9876543210'),
      );

      await store.clear();
      final read = await store.read();

      expect(read.name, '');
      expect(read.phone, '');
    });

    test('edge: clearing an already-empty store is a no-op', () async {
      await store.clear();
      final read = await store.read();

      expect(read.name, '');
    });
  });
}
