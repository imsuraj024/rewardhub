import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/qr_scan/data/models/qr_scan_response_model.dart';
import 'package:rewardhub/features/qr_scan/domain/usecases/submit_qr_scan_usecase.dart';
import 'package:rewardhub/features/qr_scan/presentation/controllers/qr_scan_controller.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockAuthController extends Mock implements AuthController {}

class MockSubmitQrScanUseCase extends Mock implements SubmitQrScanUseCase {}

BarcodeCapture _capture(String? raw) =>
    BarcodeCapture(barcodes: [Barcode(rawValue: raw)]);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late AnalyticsHarness analytics;
  late MockAuthController auth;
  late MockSubmitQrScanUseCase submit;
  late ShellController shell;
  late List<({bool success, String message})> results;

  setUpAll(() {
    registerFallbackValue(
      const SubmitQrScanParams(qrData: 'x', token: 't'),
    );
  });

  setUp(() {
    analytics = AnalyticsHarness();
    installGetTestHarness();
    auth = MockAuthController();
    submit = MockSubmitQrScanUseCase();
    shell = ShellController(analytics.analytics);
    results = [];
  });

  tearDown(resetGet);

  // Built WITHOUT onInit so the camera-permission platform channel and the
  // WidgetsBinding observer are never touched (see gap notes in report).
  // presentResult captures outcomes: the real one is a GetX snackbar, which
  // needs an overlay these pure-Dart tests do not have.
  QrScanController build() => QrScanController(
        submitQrScan: submit,
        authController: auth,
        shellController: shell,
        analytics: analytics.analytics,
        presentResult: ({required bool success, required String message}) =>
            results.add((success: success, message: message)),
      );

  group('onDetect', () {
    test('positive: valid barcode with token submits the scan', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, pointsEarned: 25),
      );
      final c = build();

      c.onDetect(_capture('QR-PAYLOAD'));
      await _settle();

      final params =
          verify(() => submit.call(captureAny())).captured.single
              as SubmitQrScanParams;
      expect(params.qrData, 'QR-PAYLOAD');
      expect(params.token, 'jwt');
      expect(c.isSubmitting.value, isFalse);
      expect(results.single.success, isTrue);
      expect(results.single.message, 'You earned 25 pts!');
    });

    test('positive: response without points still submits/succeeds', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, message: 'ok'),
      );
      final c = build();

      c.onDetect(_capture('QR'));
      await _settle();
      expect(results.single.success, isTrue);

      verify(() => submit.call(any())).called(1);
      expect(c.isSubmitting.value, isFalse);
    });

    test('negative: null token surfaces session error, no submit', () async {
      when(() => auth.token).thenReturn(null);
      final c = build();

      c.onDetect(_capture('QR'));
      await _settle();

      verifyNever(() => submit.call(any()));
    });

    test('negative: submit failure is handled and resets submitting',
        () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenThrow(ApiException('bad code'));
      final c = build();

      c.onDetect(_capture('QR'));
      await _settle();

      verify(() => submit.call(any())).called(1);
      expect(c.isSubmitting.value, isFalse);
    });

    test('edge: null barcode rawValue is ignored', () async {
      when(() => auth.token).thenReturn('jwt');
      final c = build();

      c.onDetect(_capture(null));
      await _settle();

      verifyNever(() => submit.call(any()));
    });

    test('edge: empty barcode list is ignored', () async {
      when(() => auth.token).thenReturn('jwt');
      final c = build();

      c.onDetect(const BarcodeCapture(barcodes: []));
      await _settle();

      verifyNever(() => submit.call(any()));
    });

    test('edge: ignored while a submit is already in flight', () async {
      when(() => auth.token).thenReturn('jwt');
      final c = build();
      c.isSubmitting.value = true;

      c.onDetect(_capture('QR'));
      await _settle();

      verifyNever(() => submit.call(any()));
    });

    test('positive: subsequent detection after completion is processed (auto rescan)',
        () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, pointsEarned: 1),
      );
      final c = build();

      c.onDetect(_capture('FIRST'));
      await _settle();
      c.onDetect(_capture('SECOND'));
      await _settle();

      // Auto-rescan on result re-arms detection so both codes are processed.
      verify(() => submit.call(any())).called(2);
    });
  });

  group('rescan', () {
    test('edge: rescan re-arms detection without throwing', () {
      final c = build();
      expect(c.rescan, returnsNormally);
    });
  });

  group('didChangeAppLifecycleState', () {
    test('negative: no-op when camera permission is not granted', () {
      final c = build();
      expect(c.cameraStatus.value.isGranted, isFalse);

      expect(
        () => c.didChangeAppLifecycleState(AppLifecycleState.resumed),
        returnsNormally,
      );
    });

    test('negative: no-op when granted but not on the qr tab', () {
      final c = build();
      c.cameraStatus.value = PermissionStatus.granted;
      shell.currentIndex.value = ShellTab.home.index; // not the qr tab

      expect(
        () => c.didChangeAppLifecycleState(AppLifecycleState.resumed),
        returnsNormally,
      );
    });

    test('edge: granted + on qr tab handles resume/pause without throwing', () {
      final c = build();
      c.cameraStatus.value = PermissionStatus.granted;
      shell.currentIndex.value = QrScanController.qrTabIndex;

      expect(
        () => c.didChangeAppLifecycleState(AppLifecycleState.resumed),
        returnsNormally,
      );
      expect(
        () => c.didChangeAppLifecycleState(AppLifecycleState.paused),
        returnsNormally,
      );
      expect(
        () => c.didChangeAppLifecycleState(AppLifecycleState.inactive),
        returnsNormally,
      );
    });
  });

  group('analytics', () {
    test('positive: a successful scan reports detection then points', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, pointsEarned: 25),
      );

      build().onDetect(_capture('QR-PAYLOAD'));
      await _settle();

      expect(analytics.names, ['qr_code_detected', 'qr_scan_succeeded']);
      expect(analytics.call('qr_scan_succeeded')!.parameters['points_earned'],
          25);
    });

    test('negative: the scanned payload never reaches an event', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, pointsEarned: 25),
      );

      build().onDetect(_capture('SECRET-QR-PAYLOAD'));
      await _settle();

      final payload =
          analytics.service.allParameterValues.map((v) => v.toString()).join();
      expect(payload, isNot(contains('SECRET-QR-PAYLOAD')));
    });

    test('negative: a missing session reports no_session', () async {
      when(() => auth.token).thenReturn(null);

      build().onDetect(_capture('QR'));
      await _settle();

      expect(analytics.call('qr_scan_failed')!.parameters['reason'],
          'no_session');
    });

    test('negative: a submit error maps to a bounded reason', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenThrow(NoInternetException());

      build().onDetect(_capture('QR'));
      await _settle();

      expect(analytics.call('qr_scan_failed')!.parameters['reason'],
          'no_internet');
    });

    test('edge: a response without points omits points_earned', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, message: 'ok'),
      );

      build().onDetect(_capture('QR'));
      await _settle();

      final call = analytics.call('qr_scan_succeeded')!;
      expect(call.parameters.containsKey('points_earned'), isFalse);
    });
  });
}
