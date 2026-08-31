import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/wallet/data/models/raise_request_response_model.dart';
import 'package:rewardhub/features/wallet/domain/usecases/raise_wallet_request_usecase.dart';
import 'package:rewardhub/features/wallet/presentation/controllers/wallet_controller.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockAuthController extends Mock implements AuthController {}

class MockRaiseWalletRequestUseCase extends Mock
    implements RaiseWalletRequestUseCase {}

void main() {
  late AnalyticsHarness analytics;
  late MockAuthController auth;
  late MockRaiseWalletRequestUseCase raise;

  setUp(() {
    analytics = AnalyticsHarness();
    installGetTestHarness();
    auth = MockAuthController();
    raise = MockRaiseWalletRequestUseCase();
  });

  tearDown(resetGet);

  WalletController build() =>
      WalletController(
        authController: auth,
        raiseWalletRequest: raise,
        analytics: analytics.analytics,
      );

  group('raiseRequest', () {
    test('positive: raises request and finishes not submitting', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => raise.call(any())).thenAnswer(
        (_) async => const RaiseRequestResponseModel(
          success: true,
          message: 'done',
        ),
      );
      final c = build();

      await c.raiseRequest();

      verify(() => raise.call('jwt')).called(1);
      expect(c.isSubmitting.value, isFalse);
    });

    test('positive: null message still succeeds (uses default text)',
        () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => raise.call(any())).thenAnswer(
        (_) async => const RaiseRequestResponseModel(success: true),
      );
      final c = build();

      await c.raiseRequest();

      verify(() => raise.call('jwt')).called(1);
      expect(c.isSubmitting.value, isFalse);
    });

    test('negative: null token short-circuits without calling usecase',
        () async {
      when(() => auth.token).thenReturn(null);
      final c = build();

      await c.raiseRequest();

      verifyNever(() => raise.call(any()));
      expect(c.isSubmitting.value, isFalse);
    });

    test('negative: empty token short-circuits without calling usecase',
        () async {
      when(() => auth.token).thenReturn('');
      final c = build();

      await c.raiseRequest();

      verifyNever(() => raise.call(any()));
      expect(c.isSubmitting.value, isFalse);
    });

    test('negative: thrown error is caught and submitting is reset', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => raise.call(any())).thenThrow(ApiException('server down'));
      final c = build();

      await c.raiseRequest();

      expect(c.isSubmitting.value, isFalse);
    });

    test('edge: overlapping call is ignored while submitting', () async {
      when(() => auth.token).thenReturn('jwt');
      final c = build();
      c.isSubmitting.value = true;

      await c.raiseRequest();

      verifyNever(() => raise.call(any()));
    });

    test('edge: submitting flag is set true during the in-flight request',
        () async {
      when(() => auth.token).thenReturn('jwt');
      final completer = Completer<RaiseRequestResponseModel>();
      when(() => raise.call(any())).thenAnswer((_) => completer.future);
      final c = build();

      final future = c.raiseRequest();
      expect(c.isSubmitting.value, isTrue);

      completer.complete(const RaiseRequestResponseModel(success: true));
      await future;
      expect(c.isSubmitting.value, isFalse);
    });
  });

  group('analytics', () {
    test('positive: a successful redeem reports request then success', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => raise.call(any())).thenAnswer(
        (_) async => const RaiseRequestResponseModel(success: true),
      );

      await build().raiseRequest();

      expect(analytics.names, ['redeem_requested', 'redeem_succeeded']);
    });

    test('negative: a missing session reports a no_session failure', () async {
      when(() => auth.token).thenReturn(null);

      await build().raiseRequest();

      expect(analytics.names, ['redeem_requested', 'redeem_failed']);
      expect(analytics.call('redeem_failed')!.parameters['reason'],
          'no_session');
    });

    test('negative: a thrown error reports a mapped reason', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => raise.call(any())).thenThrow(NoInternetException());

      await build().raiseRequest();

      expect(analytics.call('redeem_failed')!.parameters['reason'],
          'no_internet');
    });

    test('edge: an overlapping tap reports nothing at all', () async {
      when(() => auth.token).thenReturn('jwt');
      final c = build();
      c.isSubmitting.value = true;

      await c.raiseRequest();

      expect(analytics.names, isEmpty);
    });
  });
}
