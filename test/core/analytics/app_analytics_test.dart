import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/network/api_exception.dart';

import '../../helpers/recording_analytics.dart';

/// These tests pin the **wire contract** — the exact event names and parameter
/// keys/values that reach GA4. They are deliberately literal: renaming an event
/// silently splits a metric in Firebase and the old data becomes unreachable, so
/// a rename should have to break a test.
void main() {
  late RecordingAnalyticsService service;
  late AppAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = AppAnalytics(service);
  });

  group('GA4 naming rules', () {
    // Every event this app can emit, invoked once.
    Future<void> emitEverything() async {
      await analytics.screenView('home');
      await analytics.otpRequested(isResend: false);
      await analytics.otpIncomplete(digitsEntered: 3);
      await analytics.otpVerificationFailed(ApiException('x'));
      await analytics.loginSucceeded();
      await analytics.loginFailed('rejected');
      await analytics.registrationStarted();
      await analytics
          .registrationStepCompleted(RegistrationStep.personalDetails);
      await analytics.termsNotAccepted();
      await analytics.bankDetailsRevealed();
      await analytics.kycDocumentCaptured(
        document: KycDocument.aadhaar,
        source: KycCaptureSource.camera,
      );
      await analytics.kycCaptureFailed(source: KycCaptureSource.gallery);
      await analytics.kycIncomplete(hasAadhaar: true, hasSelfie: false);
      await analytics.signUpSucceeded();
      await analytics.signUpFailed(ApiException('x'));
      await analytics.logout();
      await analytics.sessionExpired();
      await analytics.cameraPermissionResult(granted: true);
      await analytics.qrCodeDetected();
      await analytics.qrScanSucceeded(points: 25);
      await analytics.qrScanFailed(ApiException('x'));
      await analytics.qrRescanTapped();
      await analytics.redeemRequested();
      await analytics.redeemSucceeded();
      await analytics.redeemFailed(ApiException('x'));
      await analytics.tabSelected('qr_scan');
      await analytics.quickActionTapped('scan_qr');
      await analytics.faqQuestionExpanded('How do I earn points?');
      await analytics.settingsItemTapped('help_and_support');
      await analytics.supportEmailCopied();
    }

    test('positive: every event name is snake_case and within 40 chars',
        () async {
      await emitEverything();

      expect(service.calls, isNotEmpty);
      for (final call in service.calls) {
        expect(
          call.name,
          matches(RegExp(r'^[a-z][a-z0-9_]*$')),
          reason: '"${call.name}" must be snake_case starting with a letter',
        );
        expect(call.name.length, lessThanOrEqualTo(40), reason: call.name);
      }
    });

    test('positive: every parameter key is snake_case and within 40 chars',
        () async {
      await emitEverything();

      for (final call in service.calls) {
        for (final key in call.parameters.keys) {
          expect(
            key,
            matches(RegExp(r'^[a-z][a-z0-9_]*$')),
            reason: '"$key" on ${call.name}',
          );
          expect(key.length, lessThanOrEqualTo(40), reason: key);
        }
      }
    });

    test('positive: parameter values are only String, num or bool', () async {
      await emitEverything();

      for (final call in service.calls) {
        for (final value in call.parameters.values) {
          expect(
            value,
            anyOf(isA<String>(), isA<num>(), isA<bool>()),
            reason: 'on ${call.name}',
          );
        }
      }
    });

    test('positive: string values stay within the 100-char limit', () async {
      await emitEverything();

      for (final call in service.calls) {
        for (final value in call.parameters.values) {
          if (value is String) {
            expect(value.length, lessThanOrEqualTo(100), reason: call.name);
          }
        }
      }
    });

    test('edge: an over-long string value is truncated, not dropped', () async {
      await analytics.faqQuestionExpanded('q' * 250);

      final value = service.single.parameters['faq_question']! as String;
      expect(value.length, 100);
      expect(value, 'q' * 100);
    });

    test('positive: no two methods reuse a name with a different payload shape',
        () async {
      await emitEverything();

      final shapes = <String, Set<String>>{};
      for (final call in service.calls) {
        shapes
            .putIfAbsent(call.name, () => call.parameters.keys.toSet())
            .addAll(call.parameters.keys);
      }
      // login_failed is emitted from two call sites; both must carry `reason`.
      expect(shapes['login_failed'], {'reason'});
    });
  });

  group('no personal data', () {
    test('negative: nothing resembling personal data reaches an event',
        () async {
      // Values a careless implementation might have passed through.
      const forbidden = <String>[
        '9876543210', // phone
        'Priya Sharma', // name
        '123456', // OTP
        'priya@okhdfcbank', // UPI id
        '50100123456789', // account number
        'HDFC0001234', // IFSC
        'eyJhbGciOi', // JWT fragment
        '/data/user/0/aadhaar.jpg', // KYC image path
      ];

      await analytics.otpRequested(isResend: true);
      await analytics.otpIncomplete(digitsEntered: 6);
      await analytics.loginSucceeded();
      await analytics.signUpSucceeded();
      await analytics.kycDocumentCaptured(
        document: KycDocument.aadhaar,
        source: KycCaptureSource.camera,
      );
      await analytics.qrScanSucceeded(points: 25);
      await analytics.setPayoutMethod(hasUpi: true, hasBank: true);

      final serialised = [
        ...service.allParameterValues.map((v) => v.toString()),
        ...service.userProperties.values.whereType<String>(),
      ].join('|');

      for (final secret in forbidden) {
        expect(
          serialised,
          isNot(contains(secret)),
          reason: '$secret must never be sent to analytics',
        );
      }
    });

    test('negative: a raw server message is never used as a failure reason',
        () async {
      await analytics.qrScanFailed(
        ApiException('User 9876543210 has insufficient balance'),
      );

      final reason = service.single.parameters['reason']! as String;
      expect(reason, 'api');
      expect(reason, isNot(contains('9876543210')));
    });
  });

  group('failure reasons', () {
    test('positive: exception types map to stable, bounded reasons', () async {
      final cases = <Object?, String>{
        NoInternetException(): 'no_internet',
        NetworkException(): 'no_internet',
        UnauthorizedException(): 'unauthorized',
        ValidationException(): 'validation',
        ServerException(): 'server',
        ApiException('x'): 'api',
        ArgumentError('x'): 'unknown',
        null: 'unknown',
      };

      for (final entry in cases.entries) {
        service.clear();
        await analytics.qrScanFailed(entry.key);
        expect(
          service.single.parameters['reason'],
          entry.value,
          reason: '${entry.key.runtimeType}',
        );
      }
    });

    test('positive: a String is passed through as an already-mapped reason',
        () async {
      await analytics.qrScanFailed('no_session');

      expect(service.single.parameters['reason'], 'no_session');
    });
  });

  group('reserved events', () {
    test('positive: login uses GA4 login with the phone method', () async {
      await analytics.loginSucceeded();

      expect(service.single.name, 'login');
      expect(service.single.parameters['method'], 'phone');
    });

    test('positive: registration uses GA4 sign_up', () async {
      await analytics.signUpSucceeded();

      expect(service.single.name, 'sign_up');
      expect(service.single.parameters['method'], 'phone');
    });

    test('positive: taps use GA4 select_content', () async {
      await analytics.quickActionTapped('redeem');

      expect(service.single.name, 'select_content');
      expect(service.single.parameters, {
        'content_type': 'quick_action',
        'item_id': 'redeem',
      });
    });

    test('positive: screen views use GA4 screen_view', () async {
      await analytics.screenView('shell_home');

      expect(service.single.name, 'screen_view');
      expect(service.single.parameters['screen_name'], 'shell_home');
    });
  });

  group('payload details', () {
    test('positive: registration steps carry snake_case step values', () async {
      for (final step in RegistrationStep.values) {
        service.clear();
        await analytics.registrationStepCompleted(step);
        expect(
          service.single.parameters['step'],
          matches(RegExp(r'^[a-z][a-z_]*$')),
        );
      }
      // Pin the wire values so a Dart rename cannot silently change them.
      expect(RegistrationStep.personalDetails.value, 'personal_details');
      expect(RegistrationStep.accountDetails.value, 'account_details');
      expect(RegistrationStep.kyc.value, 'kyc');
    });

    test('edge: qr_scan_succeeded omits points when the response had none',
        () async {
      await analytics.qrScanSucceeded();

      expect(service.single.name, 'qr_scan_succeeded');
      expect(service.single.parameters.containsKey('points_earned'), isFalse);
    });

    test('positive: qr_scan_succeeded carries points as a number', () async {
      await analytics.qrScanSucceeded(points: 25);

      expect(service.single.parameters['points_earned'], 25);
    });

    test('positive: booleans are sent as booleans, not strings', () async {
      await analytics.cameraPermissionResult(granted: true);

      expect(service.single.parameters['granted'], isTrue);
      expect(service.single.parameters['granted'], isA<bool>());
    });
  });

  group('identity', () {
    test('positive: identify sets the opaque profile id', () async {
      await analytics.identify('usr_9f2b');

      expect(service.userIds, ['usr_9f2b']);
    });

    test('edge: an empty profile id is ignored rather than clearing identity',
        () async {
      await analytics.identify('');

      expect(service.userIds, isEmpty);
    });

    test('positive: clearIdentity drops both the id and collected data',
        () async {
      await analytics.identify('usr_9f2b');
      await analytics.clearIdentity();

      expect(service.userIds, ['usr_9f2b', null]);
      expect(service.resetCount, 1);
    });
  });

  group('payout_method user property', () {
    test('positive: reflects which kinds were configured, never the values',
        () async {
      final cases = <({bool upi, bool bank}), String>{
        (upi: true, bank: true): 'upi_and_bank',
        (upi: true, bank: false): 'upi',
        (upi: false, bank: true): 'bank',
        (upi: false, bank: false): 'none',
      };

      for (final entry in cases.entries) {
        await analytics.setPayoutMethod(
          hasUpi: entry.key.upi,
          hasBank: entry.key.bank,
        );
        expect(service.userProperties['payout_method'], entry.value);
      }
    });

    test('positive: the value stays within the 36-char user-property limit',
        () async {
      await analytics.setPayoutMethod(hasUpi: true, hasBank: true);

      final value = service.userProperties['payout_method']!;
      expect(value.length, lessThanOrEqualTo(36));
    });
  });
}
