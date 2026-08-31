import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/login_controller.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockAuthController extends Mock implements AuthController {}

void main() {
  late AnalyticsHarness analytics;
  late MockAuthController auth;

  setUp(() {
    analytics = AnalyticsHarness();
    installGetTestHarness();
    auth = MockAuthController();
  });

  tearDown(resetGet);

  /// Mounts a Form bound to [c.formKey] / [c.phoneController] so
  /// `formKey.currentState!.validate()` has a live form to run against.
  Future<void> mountForm(
    WidgetTester tester,
    LoginController c, {
    bool valid = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: c.formKey,
            child: TextFormField(
              controller: c.phoneController,
              validator: (_) => valid ? null : 'invalid',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('onReady', () {
    test('positive: clears any stale auth error', () {
      when(() => auth.clearError()).thenReturn(null);
      final c = LoginController(auth, analytics.analytics);

      c.onReady();

      verify(() => auth.clearError()).called(1);
    });
  });

  group('onContinue', () {
    testWidgets('positive: existing user logs in with sanitized phone',
        (tester) async {
      when(() => auth.login(any())).thenAnswer((_) async {});
      when(() => auth.errorMessage).thenReturn(null);
      when(() => auth.isNewUser).thenReturn(false);
      final c = LoginController(auth, analytics.analytics);
      await mountForm(tester, c);
      c.phoneController.text = '98765 43210';

      await c.onContinue();

      // Non-digits stripped before delegating to auth.
      verify(() => auth.login('9876543210')).called(1);
    });

    testWidgets('positive: new user path still logs in (routes to register)',
        (tester) async {
      when(() => auth.login(any())).thenAnswer((_) async {});
      when(() => auth.errorMessage).thenReturn(null);
      when(() => auth.isNewUser).thenReturn(true);
      final c = LoginController(auth, analytics.analytics);
      await mountForm(tester, c);
      c.phoneController.text = '9876543210';

      await c.onContinue();

      verify(() => auth.login('9876543210')).called(1);
    });

    testWidgets('negative: invalid form short-circuits before login',
        (tester) async {
      when(() => auth.login(any())).thenAnswer((_) async {});
      final c = LoginController(auth, analytics.analytics);
      await mountForm(tester, c, valid: false);
      c.phoneController.text = '9876543210';

      await c.onContinue();

      verifyNever(() => auth.login(any()));
    });

    testWidgets('negative: auth error surfaces and stops navigation',
        (tester) async {
      when(() => auth.login(any())).thenAnswer((_) async {});
      when(() => auth.errorMessage).thenReturn('blocked');
      final c = LoginController(auth, analytics.analytics);
      await mountForm(tester, c);
      c.phoneController.text = '9876543210';

      await c.onContinue();

      // login attempted, but errorMessage != null aborts before isNewUser read.
      verify(() => auth.login('9876543210')).called(1);
      verifyNever(() => auth.isNewUser);
    });

    testWidgets('edge: whitespace/symbols are stripped to bare digits',
        (tester) async {
      when(() => auth.login(any())).thenAnswer((_) async {});
      when(() => auth.errorMessage).thenReturn(null);
      when(() => auth.isNewUser).thenReturn(false);
      final c = LoginController(auth, analytics.analytics);
      await mountForm(tester, c);
      c.phoneController.text = '  +91-98(765)43210  ';

      await c.onContinue();

      verify(() => auth.login('919876543210')).called(1);
    });
  });
}
