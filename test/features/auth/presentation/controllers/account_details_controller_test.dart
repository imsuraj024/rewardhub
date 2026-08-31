import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';
import 'package:rewardhub/features/auth/presentation/controllers/account_details_controller.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockRegistrationDraftStore extends Mock
    implements RegistrationDraftStore {}

void main() {
  late AnalyticsHarness analytics;
  late MockRegistrationDraftStore store;

  setUpAll(() {
    registerFallbackValue(const RegistrationDraft());
  });

  setUp(() {
    analytics = AnalyticsHarness();
    installGetTestHarness();
    store = MockRegistrationDraftStore();
    when(() => store.read()).thenAnswer((_) async => const RegistrationDraft());
    when(() => store.save(any())).thenAnswer((_) async {});
  });

  tearDown(resetGet);

  Future<void> mountForm(
    WidgetTester tester,
    AccountDetailsController c, {
    bool valid = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: c.formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: c.upiController,
                  validator: (_) => valid ? null : 'invalid',
                ),
                TextFormField(controller: c.accountNumberController),
                TextFormField(controller: c.ifscController),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('revealBankDetails', () {
    test('positive: flips the bank-details flag on', () {
      final c = AccountDetailsController(store, analytics.analytics);
      expect(c.showBankDetails.value, isFalse);

      c.revealBankDetails();

      expect(c.showBankDetails.value, isTrue);
    });
  });

  group('onInit / prefill', () {
    test('positive: prefills upi and keeps bank section closed when empty',
        () async {
      when(() => store.read()).thenAnswer(
        (_) async => const RegistrationDraft(upi: 'ada@upi'),
      );
      final c = AccountDetailsController(store, analytics.analytics);

      c.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(c.upiController.text, 'ada@upi');
      expect(c.showBankDetails.value, isFalse);
    });

    test('edge: reopens bank section when a saved account number exists',
        () async {
      when(() => store.read()).thenAnswer(
        (_) async => const RegistrationDraft(accountNumber: '123456'),
      );
      final c = AccountDetailsController(store, analytics.analytics);

      c.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(c.accountNumberController.text, '123456');
      expect(c.showBankDetails.value, isTrue);
    });

    test('edge: reopens bank section when a saved ifsc exists', () async {
      when(() => store.read()).thenAnswer(
        (_) async => const RegistrationDraft(ifsc: 'HDFC0001'),
      );
      final c = AccountDetailsController(store, analytics.analytics);

      c.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(c.showBankDetails.value, isTrue);
    });
  });

  group('onNext', () {
    testWidgets('positive: saves upi and blanks bank fields when hidden',
        (tester) async {
      final c = AccountDetailsController(store, analytics.analytics);
      await mountForm(tester, c);
      c.upiController.text = ' ada@upi ';
      c.accountNumberController.text = '999999';
      c.ifscController.text = 'HDFC0001';
      // showBankDetails stays false -> bank fields must not be persisted.

      await c.onNext();

      final draft = verify(() => store.save(captureAny())).captured.single
          as RegistrationDraft;
      expect(draft.upi, 'ada@upi');
      expect(draft.accountNumber, '');
      expect(draft.ifsc, '');
    });

    testWidgets('positive: persists bank fields when revealed', (tester) async {
      final c = AccountDetailsController(store, analytics.analytics);
      await mountForm(tester, c);
      c.revealBankDetails();
      c.accountNumberController.text = ' 999999 ';
      c.ifscController.text = ' HDFC0001 ';

      await c.onNext();

      final draft = verify(() => store.save(captureAny())).captured.single
          as RegistrationDraft;
      expect(draft.accountNumber, '999999');
      expect(draft.ifsc, 'HDFC0001');
    });

    testWidgets('negative: invalid form short-circuits before save',
        (tester) async {
      final c = AccountDetailsController(store, analytics.analytics);
      await mountForm(tester, c, valid: false);

      await c.onNext();

      verifyNever(() => store.save(any()));
    });
  });
}
