import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/features/auth/data/models/login_response_model.dart';
import 'package:rewardhub/features/auth/data/models/register_response_model.dart';
import 'package:rewardhub/features/auth/domain/usecases/login_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/logout_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/register_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';

import '../../../helpers/harness.dart';
import '../../../helpers/recording_analytics.dart';

import 'package:rewardhub/features/auth/domain/usecases/delete_account_usecase.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}

class MockRestoreSessionUseCase extends Mock
    implements RestoreSessionUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockDeleteAccountUseCase extends Mock implements DeleteAccountUseCase {}

void main() {
  late AnalyticsHarness analytics;
  late MockLoginUseCase login;
  late MockRegisterUseCase register;
  late MockVerifyOtpUseCase verifyOtp;
  late MockRestoreSessionUseCase restoreSession;
  late MockLogoutUseCase logout;
  late MockDeleteAccountUseCase deleteAccount;
  late List<RecordedToast> toasts;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const RegisterParams(name: 'x', phone: '1', referralCode: 'r'),
    );
    registerFallbackValue(const VerifyOtpParams(token: 't', otp: '123456'));
  });

  setUp(() {
    analytics = AnalyticsHarness();
    toasts = installGetTestHarness();
    login = MockLoginUseCase();
    register = MockRegisterUseCase();
    verifyOtp = MockVerifyOtpUseCase();
    restoreSession = MockRestoreSessionUseCase();
    logout = MockLogoutUseCase();
    deleteAccount = MockDeleteAccountUseCase();
  });

  AuthController build() => AuthController(
        loginUseCase: login,
        registerUseCase: register,
        verifyOtpUseCase: verifyOtp,
        restoreSessionUseCase: restoreSession,
        logoutUseCase: logout,
        deleteAccountUseCase: deleteAccount,
        analytics: analytics.analytics,
      );

  /// Brings the controller to an authenticated state the way the app does.
  Future<AuthController> authenticated() async {
    when(() => restoreSession.call(any())).thenAnswer((_) async => 'jwt');
    final c = build();
    await c.restoreSession();
    expect(c.isAuthenticated, isTrue, reason: 'precondition');
    return c;
  }

  group('login', () {
    test('positive: existing user success sets token, no error', () async {
      when(() => login.call(any())).thenAnswer(
        (_) async => LoginResponseModel(
          success: true,
          isNewUser: false,
          token: 'jwt',
        ),
      );
      final c = build();

      await c.login('9876543210');

      expect(c.token, 'jwt');
      expect(c.isNewUser, isFalse);
      expect(c.errorMessage, isNull);
      expect(c.isLoading, isFalse);
    });

    test('positive: new user flag set, no error even without token', () async {
      when(() => login.call(any())).thenAnswer(
        (_) async =>
            LoginResponseModel(success: false, isNewUser: true, token: null),
      );
      final c = build();

      await c.login('9876543210');

      expect(c.isNewUser, isTrue);
      expect(c.errorMessage, isNull);
    });

    test('negative: unsuccessful non-new user surfaces message', () async {
      when(() => login.call(any())).thenAnswer(
        (_) async => LoginResponseModel(
          success: false,
          isNewUser: false,
          message: 'blocked',
        ),
      );
      final c = build();

      await c.login('9876543210');

      expect(c.errorMessage, 'blocked');
    });

    test('negative: thrown ApiException is resolved to its message', () async {
      when(() => login.call(any())).thenThrow(ApiException('server down'));
      final c = build();

      await c.login('9876543210');

      expect(c.errorMessage, 'server down');
      expect(c.isLoading, isFalse);
    });
  });

  group('verifyOtp', () {
    test('negative: no token yields session-expired error', () async {
      final c = build();

      await c.verifyOtp('123456');

      expect(c.errorMessage, contains('logged out'));
      verifyNever(() => verifyOtp.call(any()));
    });

    test('positive: with token, verifies and authenticates', () async {
      when(() => login.call(any())).thenAnswer(
        (_) async =>
            LoginResponseModel(success: true, isNewUser: false, token: 'jwt'),
      );
      when(() => verifyOtp.call(any())).thenAnswer((_) async {});
      final c = build();
      await c.login('9876543210');

      await c.verifyOtp('123456');

      expect(c.isAuthenticated, isTrue);
      expect(c.errorMessage, isNull);
    });

    test('negative: verify failure surfaces error, stays unauthenticated',
        () async {
      when(() => login.call(any())).thenAnswer(
        (_) async =>
            LoginResponseModel(success: true, isNewUser: false, token: 'jwt'),
      );
      when(() => verifyOtp.call(any()))
          .thenThrow(ValidationException('bad otp', 422));
      final c = build();
      await c.login('9876543210');

      await c.verifyOtp('000000');

      expect(c.isAuthenticated, isFalse);
      expect(c.errorMessage, 'bad otp');
    });
  });

  group('register', () {
    test('positive: stores issued token', () async {
      when(() => register.call(any())).thenAnswer(
        (_) async => RegisterResponseModel(success: true, token: 'newjwt'),
      );
      final c = build();

      await c.register(name: 'A', phone: '1', referralCode: 'R');

      expect(c.token, 'newjwt');
      expect(c.errorMessage, isNull);
    });

    test('negative: thrown error is surfaced', () async {
      when(() => register.call(any())).thenThrow(ApiException('dup phone'));
      final c = build();

      await c.register(name: 'A', phone: '1', referralCode: 'R');

      expect(c.errorMessage, 'dup phone');
    });
  });

  group('restoreSession', () {
    test('positive: token present authenticates', () async {
      when(() => restoreSession.call(any()))
          .thenAnswer((_) async => 'saved-jwt');
      final c = build();

      await c.restoreSession();

      expect(c.isAuthenticated, isTrue);
      expect(c.token, 'saved-jwt');
      expect(c.isSessionRestored, isTrue);
    });

    test('edge: null token leaves user logged out but marks restored',
        () async {
      when(() => restoreSession.call(any())).thenAnswer((_) async => null);
      final c = build();

      await c.restoreSession();

      expect(c.isAuthenticated, isFalse);
      expect(c.isSessionRestored, isTrue);
    });

    test('negative: thrown error still marks session restored', () async {
      when(() => restoreSession.call(any())).thenThrow(Exception('boom'));
      final c = build();

      await c.restoreSession();

      expect(c.isSessionRestored, isTrue);
      expect(c.isAuthenticated, isFalse);
    });
  });

  group('logout & clearError', () {
    test('logout clears session state', () async {
      when(() => logout.call(any())).thenAnswer((_) async {});
      final c = build();

      await c.logout();

      expect(c.token, isNull);
      expect(c.isAuthenticated, isFalse);
      expect(c.isNewUser, isFalse);
    });

    test('clearError resets the message', () async {
      when(() => login.call(any())).thenThrow(ApiException('x'));
      final c = build();
      await c.login('1');
      expect(c.errorMessage, isNotNull);

      c.clearError();

      expect(c.errorMessage, isNull);
    });
  });

  group('deleteAccount', () {
    test('positive: when authenticated, calling deleteAccount invokes usecase and clears session', () async {
      when(() => deleteAccount.call('jwt')).thenAnswer((_) async {});
      final c = await authenticated();

      final success = await c.deleteAccount();

      expect(success, isTrue);
      expect(c.isAuthenticated, isFalse);
      expect(c.token, isNull);
      verify(() => deleteAccount.call('jwt')).called(1);
    });

    test('negative: when unauthenticated, returns false without calling usecase', () async {
      final c = build();

      final success = await c.deleteAccount();

      expect(success, isFalse);
      verifyNever(() => deleteAccount.call(any()));
    });

    test('negative: thrown exception sets errorMessage and returns false', () async {
      when(() => deleteAccount.call('jwt')).thenThrow(ApiException('deletion error'));
      final c = await authenticated();

      final success = await c.deleteAccount();

      expect(success, isFalse);
      expect(c.errorMessage, 'deletion error');
    });
  });

  group('handleSessionExpired', () {
    test('positive: clears the session and warns the user', () async {
      final c = await authenticated();

      c.handleSessionExpired();

      expect(c.isAuthenticated, isFalse);
      expect(c.token, isNull);
      expect(c.isNewUser, isFalse);
      expect(c.errorMessage, isNull);
      expect(toasts.single.type, ToastType.warning);
      expect(toasts.single.message, contains('logged out'));
    });

    test('negative: does nothing when there is no live session', () {
      final c = build();
      expect(c.isAuthenticated, isFalse, reason: 'precondition');

      c.handleSessionExpired();

      expect(toasts, isEmpty);
    });

    test('edge: concurrent 401s only surface one message', () async {
      final c = await authenticated();

      // Several requests can be in flight and each can come back 401.
      c.handleSessionExpired();
      c.handleSessionExpired();
      c.handleSessionExpired();

      expect(toasts, hasLength(1));
      expect(c.isAuthenticated, isFalse);
    });

    test('edge: re-arms after a fresh session is restored', () async {
      final c = await authenticated();
      c.handleSessionExpired();
      expect(toasts, hasLength(1));

      await c.restoreSession();
      expect(c.isAuthenticated, isTrue);
      c.handleSessionExpired();

      expect(toasts, hasLength(2));
    });

    test('negative: does not call logout (interceptor already dropped the token)',
        () async {
      final c = await authenticated();

      c.handleSessionExpired();

      verifyNever(() => logout.call(any()));
    });
  });

  group('analytics', () {
    test('positive: a verified OTP reports GA4 login, not the OTP request',
        () async {
      when(() => login.call(any())).thenAnswer(
        (_) async => LoginResponseModel(
          success: true,
          isNewUser: false,
          token: 'jwt',
        ),
      );
      when(() => verifyOtp.call(any())).thenAnswer((_) async {});
      final c = build();
      await c.login('9876543210');
      analytics.service.clear();

      await c.verifyOtp('123456');

      // The session only exists once the OTP is verified.
      expect(analytics.names, ['login']);
      expect(analytics.call('login')!.parameters['method'], 'phone');
    });

    test('negative: the phone number never reaches an event', () async {
      when(() => login.call(any())).thenAnswer(
        (_) async => LoginResponseModel(
          success: true,
          isNewUser: false,
          token: 'jwt',
        ),
      );

      await build().login('9876543210');

      final payload =
          analytics.service.allParameterValues.map((v) => v.toString()).join();
      expect(payload, isNot(contains('9876543210')));
    });

    test('positive: a new phone number reports registration_started', () async {
      when(() => login.call(any())).thenAnswer(
        (_) async => LoginResponseModel(success: true, isNewUser: true),
      );

      await build().login('9876543210');

      expect(analytics.names, contains('registration_started'));
    });

    test('negative: a server-refused login reports reason rejected', () async {
      when(() => login.call(any())).thenAnswer(
        (_) async => LoginResponseModel(
          success: false,
          isNewUser: false,
          message: 'blocked',
        ),
      );

      await build().login('9876543210');

      expect(analytics.call('login_failed')!.parameters['reason'], 'rejected');
    });

    test('negative: a transport error maps to a bounded reason', () async {
      when(() => login.call(any())).thenThrow(NoInternetException());

      await build().login('9876543210');

      expect(
          analytics.call('login_failed')!.parameters['reason'], 'no_internet');
    });

    test('positive: verifyOtp with no session reports no_session', () async {
      await build().verifyOtp('123456');

      expect(analytics.call('otp_verification_failed')!.parameters['reason'],
          'no_session');
    });

    test('positive: session expiry reports the event and clears identity',
        () async {
      final c = await authenticated();
      analytics.service.clear();

      c.handleSessionExpired();
      // clearIdentity is deliberately not awaited in production — telemetry
      // must not delay the redirect — so let its microtasks run.
      await Future<void>.delayed(Duration.zero);

      expect(analytics.names, ['session_expired']);
      // Identity must not carry over to the next user on a shared device.
      expect(analytics.service.userIds, [null]);
      expect(analytics.service.resetCount, 1);
    });

    test('positive: logout reports the event and clears identity', () async {
      when(() => logout.call(any())).thenAnswer((_) async {});
      final c = build();

      await c.logout();
      await Future<void>.delayed(Duration.zero);

      expect(analytics.names, ['logout']);
      expect(analytics.service.userIds, [null]);
      expect(analytics.service.resetCount, 1);
    });
  });

  group('isVersionOutdated', () {
    test(
        'positive: returns true when current version is lower than latest version',
        () {
      expect(AuthController.isVersionOutdated('1.0.0', '1.1.0'), isTrue);
      expect(AuthController.isVersionOutdated('1.0.0+4', '1.0.1'), isTrue);
      expect(AuthController.isVersionOutdated('1.2.3', '2.0.0'), isTrue);
    });

    test(
        'positive: returns false when current version is equal to or higher than latest version',
        () {
      expect(AuthController.isVersionOutdated('1.1.0', '1.1.0'), isFalse);
      expect(AuthController.isVersionOutdated('2.0.0', '1.5.0'), isFalse);
    });

    test('edge: returns false when latest version is empty or invalid', () {
      expect(AuthController.isVersionOutdated('1.0.0', ''), isFalse);
      expect(AuthController.isVersionOutdated('1.0.0', '  '), isFalse);
    });
  });
}
