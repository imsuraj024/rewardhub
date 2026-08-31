import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';
import 'package:rewardhub/features/auth/presentation/controllers/personal_details_controller.dart';

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
    PersonalDetailsController c, {
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
                  controller: c.nameController,
                  validator: (_) => valid ? null : 'invalid',
                ),
                TextFormField(controller: c.phoneController),
                TextFormField(controller: c.referralController),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('setAgreedToTerms', () {
    test('positive: toggles the reactive flag', () {
      final c = PersonalDetailsController(store, analytics.analytics);
      expect(c.agreedToTerms.value, isFalse);

      c.setAgreedToTerms(true);
      expect(c.agreedToTerms.value, isTrue);

      c.setAgreedToTerms(false);
      expect(c.agreedToTerms.value, isFalse);
    });
  });

  group('onInit / prefill', () {
    test('positive: prefills the fields from the persisted draft', () async {
      when(() => store.read()).thenAnswer(
        (_) async => const RegistrationDraft(
          name: 'Ada',
          phone: '9876543210',
          referral: 'REF10',
        ),
      );
      final c = PersonalDetailsController(store, analytics.analytics);

      c.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(c.nameController.text, 'Ada');
      expect(c.phoneController.text, '9876543210');
      expect(c.referralController.text, 'REF10');
    });
  });

  group('onNext', () {
    testWidgets('positive: valid form + agreed saves sanitized draft',
        (tester) async {
      final c = PersonalDetailsController(store, analytics.analytics);
      await mountForm(tester, c);
      c.nameController.text = '  Ada  ';
      c.phoneController.text = '98765 43210';
      c.referralController.text = ' REF10 ';
      c.setAgreedToTerms(true);

      await c.onNext();

      final captured =
          verify(() => store.save(captureAny())).captured.single
              as RegistrationDraft;
      expect(captured.name, 'Ada');
      expect(captured.phone, '9876543210');
      expect(captured.referral, 'REF10');
    });

    testWidgets('negative: invalid form short-circuits before save',
        (tester) async {
      final c = PersonalDetailsController(store, analytics.analytics);
      await mountForm(tester, c, valid: false);
      c.setAgreedToTerms(true);

      await c.onNext();

      verifyNever(() => store.save(any()));
    });

    testWidgets('negative: valid form but terms not agreed does not save',
        (tester) async {
      final c = PersonalDetailsController(store, analytics.analytics);
      await mountForm(tester, c);
      c.nameController.text = 'Ada';
      // agreedToTerms stays false.

      await c.onNext();

      verifyNever(() => store.save(any()));
    });
  });
}
