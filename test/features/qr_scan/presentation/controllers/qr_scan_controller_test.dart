import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
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
  late PermissionStatus readStatus;
  late int readCalls;
  late int requestCalls;
  late Future<PermissionStatus> Function() onRequest;
  late int confirmCalls;
  late FutureOr<bool> Function() onConfirm;

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
    readStatus = PermissionStatus.denied;
    readCalls = 0;
    requestCalls = 0;
    onRequest = () async => PermissionStatus.granted;
    confirmCalls = 0;
    onConfirm = () => true;
  });

  tearDown(resetGet);

  // Built WITHOUT onInit so the WidgetsBinding observer is never touched
  // (the lifecycle group registers one through Get.put where it needs it).
  // The permission readers are fakes, so the platform channel is never hit.
  // presentResult captures outcomes and confirmSubmit answers the "Submit this
  // QR code?" question (Submit by default): the real ones are bottom sheets,
  // which need a navigator these pure-Dart tests do not have.
  QrScanController build({ScanResultPresenter? presentResult}) =>
      QrScanController(
        submitQrScan: submit,
        authController: auth,
        shellController: shell,
        analytics: analytics.analytics,
        presentResult: presentResult ??
            ({required bool success, required String message}) =>
                results.add((success: success, message: message)),
        confirmSubmit: () {
          confirmCalls++;
          return onConfirm();
        },
        readCameraStatus: () async {
          readCalls++;
          return readStatus;
        },
        requestCameraAccess: () {
          requestCalls++;
          return onRequest();
        },
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
      expect(results.single.message, 'You earned 25 points.');
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
      expect(results.single.message, 'ok');

      verify(() => submit.call(any())).called(1);
      expect(c.isSubmitting.value, isFalse);
    });

    test('negative: null token surfaces session error, no submit', () async {
      when(() => auth.token).thenReturn(null);
      final c = build();

      c.onDetect(_capture('QR'));
      await _settle();

      verifyNever(() => submit.call(any()));
      expect(results.single.success, isFalse);
      expect(results.single.message, contains('logged out'));
    });

    test('edge: no points and no server message points to Wallet', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, message: '  '),
      );

      build().onDetect(_capture('QR'));
      await _settle();

      expect(results.single.message, 'Check Wallet to see your points.');
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

    test('edge: codes are ignored until the result is dismissed', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, pointsEarned: 5),
      );
      final dismissed = Completer<void>();
      final c = build(
        presentResult: ({required bool success, required String message}) =>
            dismissed.future,
      );

      c.onDetect(_capture('FIRST'));
      await _settle();
      c.onDetect(_capture('STILL-IN-FRAME'));
      await _settle();
      verify(() => submit.call(any())).called(1);

      dismissed.complete();
      await _settle();
      c.onDetect(_capture('NEXT'));
      await _settle();
      verify(() => submit.call(any())).called(1);
    });

    test('positive: the overlay is closed before the result shows', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, pointsEarned: 5),
      );
      bool? submittingWhenShown;
      late final QrScanController c;
      c = build(
        presentResult: ({required bool success, required String message}) {
          submittingWhenShown = c.isSubmitting.value;
        },
      );

      c.onDetect(_capture('QR'));
      await _settle();

      expect(submittingWhenShown, isFalse);
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

  group('result sheet (no injected presenter)', () {
    testWidgets('positive: the sheet shows after the overlay, rescan on close',
        (tester) async {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, pointsEarned: 25),
      );
      final c = Get.put<QrScanController>(
        QrScanController(
          submitQrScan: submit,
          authController: auth,
          shellController: shell,
          analytics: analytics.analytics,
          readCameraStatus: () async => PermissionStatus.denied,
          requestCameraAccess: () async => PermissionStatus.denied,
        ),
      );
      await pumpApp(tester, const SizedBox.shrink());

      c.onDetect(_capture('QR'));
      await tester.pumpAndSettle();

      // Asked first: nothing is sent until the user taps Submit.
      expect(find.text('Submit this QR code?'), findsOneWidget);
      verifyNever(() => submit.call(any()));

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(c.isSubmitting.value, isFalse);
      expect(find.text('Points added'), findsOneWidget);
      expect(find.text('You earned 25 points.'), findsOneWidget);

      // Still open: a code in frame is not submitted again.
      c.onDetect(_capture('QR'));
      await tester.pumpAndSettle();
      verify(() => submit.call(any())).called(1);

      await tester.tap(find.text('Scan another code'));
      await tester.pumpAndSettle();

      expect(find.text('Points added'), findsNothing);

      // The next code is asked about too; "Scan again" sends nothing.
      c.onDetect(_capture('NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('Submit this QR code?'), findsOneWidget);

      await tester.tap(find.text('Scan again'));
      await tester.pumpAndSettle();

      expect(find.text('Submit this QR code?'), findsNothing);
      verifyNever(() => submit.call(any()));
    });
  });

  group('confirmation before submit', () {
    setUp(() {
      when(() => auth.token).thenReturn('jwt');
      when(() => submit.call(any())).thenAnswer(
        (_) async => QrScanResponseModel(success: true, pointsEarned: 25),
      );
    });

    test('positive: asks once, then submits on Submit', () async {
      final c = build();

      c.onDetect(_capture('QR-PAYLOAD'));
      await _settle();

      expect(confirmCalls, 1);
      verify(() => submit.call(any())).called(1);
      expect(results.single.success, isTrue);
    });

    test('positive: nothing is sent until the question is answered', () async {
      final answer = Completer<bool>();
      onConfirm = () => answer.future;
      final c = build();

      c.onDetect(_capture('QR'));
      await _settle();
      verifyNever(() => submit.call(any()));
      expect(c.isSubmitting.value, isFalse);

      answer.complete(true);
      await _settle();
      verify(() => submit.call(any())).called(1);
    });

    test('negative: "Scan again" sends nothing and shows no result', () async {
      onConfirm = () => false;
      final c = build();

      c.onDetect(_capture('QR'));
      await _settle();

      verifyNever(() => submit.call(any()));
      expect(results, isEmpty);
      expect(analytics.names, ['qr_code_detected']);

      // Re-armed: the next code is asked about again.
      c.onDetect(_capture('NEXT'));
      await _settle();
      expect(confirmCalls, 2);
    });

    test('edge: a code detected while the question is open is ignored',
        () async {
      final answer = Completer<bool>();
      onConfirm = () => answer.future;
      final c = build();

      c.onDetect(_capture('FIRST'));
      await _settle();
      c.onDetect(_capture('SECOND'));
      await _settle();
      expect(confirmCalls, 1);

      answer.complete(true);
      await _settle();
      final params =
          verify(() => submit.call(captureAny())).captured.single
              as SubmitQrScanParams;
      expect(params.qrData, 'FIRST');
    });

    test('negative: a question that fails counts as "Scan again"', () async {
      onConfirm = () => throw Exception('no navigator');
      final c = build();

      c.onDetect(_capture('QR'));
      await _settle();

      verifyNever(() => submit.call(any()));
      expect(results, isEmpty);

      onConfirm = () => true;
      c.onDetect(_capture('QR'));
      await _settle();
      verify(() => submit.call(any())).called(1);
    });
  });

  group('camera permission', () {
    test('positive: onInit reads the permission and never prompts', () async {
      Get.put<QrScanController>(build());
      await _settle();

      expect(readCalls, 1);
      expect(requestCalls, 0);
    });

    test('positive: showing the Scan tab re-reads, never prompts', () async {
      final c = Get.put<QrScanController>(build());
      await _settle();
      readStatus = PermissionStatus.granted;

      shell.currentIndex.value = QrScanController.qrTabIndex;
      await _settle();

      expect(c.cameraStatus.value, PermissionStatus.granted);
      expect(readCalls, 2);
      expect(requestCalls, 0);
    });

    test('positive: resume re-reads the status (Settings round trip)',
        () async {
      final c = build();

      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _settle();
      expect(c.cameraStatus.value, PermissionStatus.denied);

      readStatus = PermissionStatus.granted;
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _settle();

      expect(c.cameraStatus.value, PermissionStatus.granted);
      expect(requestCalls, 0);
    });

    test('positive: "Allow camera" prompts once and records the answer',
        () async {
      onRequest = () async => PermissionStatus.permanentlyDenied;
      final c = build();

      await c.requestCameraPermission();

      expect(requestCalls, 1);
      expect(c.cameraStatus.value, PermissionStatus.permanentlyDenied);
      expect(analytics.names, ['camera_permission_result']);
      expect(analytics.call('camera_permission_result')!.parameters['granted'],
          isFalse);
    });

    test('negative: passive reads never record a permission result', () async {
      final c = build();

      await c.refreshCameraStatus();
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _settle();

      expect(analytics.names, isEmpty);
    });

    test('edge: a resume during the OS prompt keeps the prompt\'s answer',
        () async {
      final answer = Completer<PermissionStatus>();
      onRequest = () => answer.future;
      final c = build();

      final pending = c.requestCameraPermission();
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _settle();
      answer.complete(PermissionStatus.granted);
      await pending;
      await _settle();

      expect(c.cameraStatus.value, PermissionStatus.granted);
      expect(readCalls, 0);
    });

    test('edge: a second tap while the prompt is open is ignored', () async {
      final answer = Completer<PermissionStatus>();
      onRequest = () => answer.future;
      final c = build();

      final first = c.requestCameraPermission();
      await c.requestCameraPermission();
      answer.complete(PermissionStatus.denied);
      await first;

      expect(requestCalls, 1);
      expect(analytics.names, ['camera_permission_result']);
    });

    test('negative: a failed read keeps the last known status', () async {
      final c = QrScanController(
        submitQrScan: submit,
        authController: auth,
        shellController: shell,
        analytics: analytics.analytics,
        presentResult: ({required bool success, required String message}) {},
        readCameraStatus: () async => throw Exception('channel down'),
        requestCameraAccess: () async => PermissionStatus.granted,
      );

      await c.refreshCameraStatus();

      expect(c.cameraStatus.value, PermissionStatus.denied);
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
