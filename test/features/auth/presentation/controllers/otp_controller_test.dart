import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/otp_controller.dart';

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

  OtpController build({String phone = '9876543210'}) =>
      OtpController(
        phone: phone,
        auth: auth,
        analytics: analytics.analytics,
      );

  void fill(OtpController c, String digits) {
    for (var i = 0; i < digits.length && i < OtpController.otpLength; i++) {
      c.controllers[i].text = digits[i];
    }
  }

  group('otp getter', () {
    test('positive: joins all six digit boxes in order', () {
      final c = build();
      fill(c, '123456');
      expect(c.otp, '123456');
    });

    test('edge: empty boxes yield an empty string', () {
      final c = build();
      expect(c.otp, '');
    });

    test('edge: partial entry returns only the filled digits', () {
      final c = build();
      fill(c, '12');
      expect(c.otp, '12');
    });
  });

  group('maskedPhone', () {
    test('positive: masks a standard 10-digit number', () {
      final c = build(phone: '9876543210');
      expect(c.maskedPhone, '9876 • •••10');
    });

    test('edge: short number (<4 chars) is returned unchanged', () {
      final c = build(phone: '99');
      expect(c.maskedPhone, '99');
    });

    test('edge: exactly 4 digits keeps no prefix window', () {
      final c = build(phone: '1234');
      // length is not > 4, so the prefix substring is empty.
      expect(c.maskedPhone, ' • •••34');
    });

    test('edge: empty phone is returned unchanged', () {
      final c = build(phone: '');
      expect(c.maskedPhone, '');
    });
  });

  group('timerLabel', () {
    test('positive: formats the default 5-minute duration', () {
      final c = build();
      expect(c.timerLabel, '05:00');
    });

    test('edge: pads single-digit minutes and seconds', () {
      final c = build();
      c.remainingSeconds.value = 65;
      expect(c.timerLabel, '01:05');
    });

    test('edge: zero seconds renders 00:00', () {
      final c = build();
      c.remainingSeconds.value = 0;
      expect(c.timerLabel, '00:00');
    });
  });

  group('onDigitChanged', () {
    test('positive: advancing from a middle box does not throw', () {
      final c = build();
      expect(() => c.onDigitChanged(0, '5'), returnsNormally);
    });

    test('edge: filling the last box does not advance/throw', () {
      final c = build();
      expect(
        () => c.onDigitChanged(OtpController.otpLength - 1, '9'),
        returnsNormally,
      );
    });

    test('edge: clearing a middle box moves focus back without throwing', () {
      final c = build();
      expect(() => c.onDigitChanged(3, ''), returnsNormally);
    });

    test('edge: clearing the first box stays put without throwing', () {
      final c = build();
      expect(() => c.onDigitChanged(0, ''), returnsNormally);
    });
  });

  group('onVerify', () {
    test('positive: full otp delegates to auth.verifyOtp', () async {
      when(() => auth.verifyOtp(any())).thenAnswer((_) async {});
      final c = build();
      fill(c, '123456');

      await c.onVerify();

      verify(() => auth.verifyOtp('123456')).called(1);
    });

    test('negative: incomplete otp warns and does not verify', () async {
      when(() => auth.verifyOtp(any())).thenAnswer((_) async {});
      final c = build();
      fill(c, '123');

      await c.onVerify();

      verifyNever(() => auth.verifyOtp(any()));
    });

    test('edge: empty otp does not verify', () async {
      when(() => auth.verifyOtp(any())).thenAnswer((_) async {});
      final c = build();

      await c.onVerify();

      verifyNever(() => auth.verifyOtp(any()));
    });
  });

  group('onResend', () {
    test('negative: gated off while canResend is false', () async {
      when(() => auth.login(any())).thenAnswer((_) async {});
      final c = build();
      expect(c.canResend.value, isFalse);

      await c.onResend();

      verifyNever(() => auth.login(any()));
    });

    test('positive: when allowed, re-requests otp and clears boxes', () async {
      when(() => auth.login(any())).thenAnswer((_) async {});
      when(() => auth.errorMessage).thenReturn(null);
      final c = build();
      fill(c, '123456');
      c.canResend.value = true;

      await c.onResend();

      verify(() => auth.login('9876543210')).called(1);
      expect(c.otp, '');
      // startTimer resets the countdown and disables resend again.
      expect(c.canResend.value, isFalse);
      expect(c.remainingSeconds.value, OtpController.timerDuration);

      c.onClose(); // stop the countdown loop started by onResend.
    });

    test('negative: login error keeps boxes intact and does not restart',
        () async {
      when(() => auth.login(any())).thenAnswer((_) async {});
      when(() => auth.errorMessage).thenReturn('rate limited');
      final c = build();
      fill(c, '123456');
      c.canResend.value = true;

      await c.onResend();

      verify(() => auth.login('9876543210')).called(1);
      // Error path returns before clearing the boxes.
      expect(c.otp, '123456');
    });
  });
}
