import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/utils/app_format.dart';
import 'package:rewardhub/core/utils/error_message.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/core/widgets/app_bottom_sheet.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/qr_scan/domain/usecases/submit_qr_scan_usecase.dart';
import 'package:rewardhub/features/qr_scan/presentation/widgets/scan_result_sheet.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';

/// Surfaces the outcome of a submitted scan to the user. The scanner restarts
/// only once the returned future completes (the result was dismissed).
///
/// Injectable so tests can capture outcomes without a live overlay.
typedef ScanResultPresenter = FutureOr<void> Function(
    {required bool success, required String message});

/// Reads or requests the camera permission.
///
/// Injectable so tests never touch the permission platform channel.
typedef CameraPermissionReader = Future<PermissionStatus> Function();

/// Asks the user whether to submit a scanned code. Resolves `true` to submit.
///
/// Injectable so tests can answer without a live navigator.
typedef ScanSubmitConfirmer = FutureOr<bool> Function();

/// Drives the QR scanner: camera permission, the scanner lifecycle (tied to the
/// active shell tab and the app lifecycle), and submitting scanned codes once
/// the user confirms them.
///
/// The [MobileScanner] widget stays mounted for the lifetime of the QR tab; the
/// camera is opened/closed purely via [_startScanner]/[_stopScanner]. Those are
/// serialized and guarded with [MobileScannerController.value.isRunning] so
/// overlapping tab/lifecycle events can never leave the camera in a bad state
/// (the cause of the "camera stops working" intermittent freeze).
///
/// The OS camera prompt appears only from [requestCameraPermission], which the
/// Scan tab's "Allow camera" button calls after an in-app explanation.
class QrScanController extends GetxController with WidgetsBindingObserver {
  QrScanController({
    required SubmitQrScanUseCase submitQrScan,
    required AuthController authController,
    required ShellController shellController,
    required AppAnalytics analytics,
    ScanResultPresenter? presentResult,
    ScanSubmitConfirmer? confirmSubmit,
    CameraPermissionReader? readCameraStatus,
    CameraPermissionReader? requestCameraAccess,
  })  : _submitQrScan = submitQrScan,
        _auth = authController,
        _shell = shellController,
        _analytics = analytics,
        _presentResult = presentResult,
        _confirmSubmit = confirmSubmit,
        _readCameraStatus =
            readCameraStatus ?? (() => Permission.camera.status),
        _requestCameraAccess =
            requestCameraAccess ?? (() => Permission.camera.request());

  final SubmitQrScanUseCase _submitQrScan;
  final AuthController _auth;
  final ShellController _shell;
  final AppAnalytics _analytics;

  /// Overrides how a scan outcome is surfaced.
  ///
  /// The default is a [ScanResultSheet], which requires a live navigator —
  /// something a pure-Dart controller test does not have. Tests pass a
  /// recorder here instead of having to pump a whole app. `null` in production.
  final ScanResultPresenter? _presentResult;

  /// Overrides how the submit question is asked. The default is an
  /// [AppBottomSheet.confirm]; `null` in production.
  final ScanSubmitConfirmer? _confirmSubmit;

  /// Reads the permission without prompting.
  final CameraPermissionReader _readCameraStatus;

  /// Shows the OS permission prompt.
  final CameraPermissionReader _requestCameraAccess;

  /// Index of the QR tab inside [ShellController].
  static int get qrTabIndex => ShellTab.qrScan.index;

  final cameraStatus = PermissionStatus.denied.obs;
  final isSubmitting = false.obs;

  // autoStart is disabled so the camera is opened explicitly only while the QR
  // tab is active — the shell keeps every tab alive in an IndexedStack, so an
  // auto-starting scanner would hold the camera open on every other tab too.
  final scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
  );

  bool _scanned = false;
  Worker? _tabWorker;

  /// The OS permission dialog is showing (it pauses and resumes the app).
  bool _requestInFlight = false;

  /// A scan result is on screen; the scanner stays off until it's dismissed.
  bool _resultOpen = false;

  /// The "Submit this QR code?" question is on screen; the scanner stays off
  /// until it's answered.
  bool _confirmOpen = false;

  /// Serializes scanner start/stop calls so they never overlap.
  Future<void> _scannerOp = Future<void>.value();

  bool get _isOnQrTab => _shell.currentIndex.value == qrTabIndex;

  /// The camera may run: permission granted, the Scan tab showing, and no
  /// scan being confirmed, checked or shown.
  bool get _canScan =>
      cameraStatus.value.isGranted &&
      _isOnQrTab &&
      !_confirmOpen &&
      !_resultOpen &&
      !isSubmitting.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // A silent read: the OS prompt never appears outside the Scan tab.
    refreshCameraStatus();

    // Scan only while the QR tab is active.
    _tabWorker = ever<int>(_shell.currentIndex, (index) {
      if (index == qrTabIndex) {
        _syncScanner();
      } else {
        _stopScanner();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Picks up a permission changed in Settings while the app was away.
      _syncScanner();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopScanner();
    }
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    scannerController.dispose();
    super.onClose();
  }

  /// Reads the permission without prompting. Called at init, when the Scan
  /// tab is shown, and on every resume.
  Future<void> refreshCameraStatus() async {
    // The OS dialog itself pauses and resumes the app; let the request's
    // own result win.
    if (_requestInFlight) return;
    try {
      cameraStatus.value = await _readCameraStatus();
    } catch (e, st) {
      log(
        'camera status read failed',
        name: 'rewardhub.qrscan',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Shows the OS camera prompt. The only caller is the "Allow camera" button.
  Future<void> requestCameraPermission() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      cameraStatus.value = await _requestCameraAccess();
    } catch (e, st) {
      log(
        'camera request failed',
        name: 'rewardhub.qrscan',
        error: e,
        stackTrace: st,
      );
      return;
    } finally {
      _requestInFlight = false;
    }
    // The gate on the entire scanning feature — measured for real requests
    // only, never for passive reads.
    _analytics.cameraPermissionResult(granted: cameraStatus.value.isGranted);
    // Granted while the Scan tab is showing: start without leaving the tab.
    if (_canScan) {
      _scanned = false;
      _startScanner();
    }
  }

  void onDetect(BarcodeCapture capture) {
    if (_scanned || isSubmitting.value) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _scanned = true;
    _stopScanner();
    // The decoded payload is deliberately not recorded.
    _analytics.qrCodeDetected();
    _confirmAndSubmit(barcode.rawValue!);
  }

  /// Asks before calling the API. "Scan again", back or a tap outside re-arms
  /// the scanner without submitting.
  Future<void> _confirmAndSubmit(String qrData) async {
    // Blocks resume, tab and rescan restarts while the question is open.
    _confirmOpen = true;
    bool confirmed;
    try {
      confirmed = await _askToSubmit();
    } catch (e, st) {
      log(
        'scan confirmation failed',
        name: 'rewardhub.qrscan',
        error: e,
        stackTrace: st,
      );
      confirmed = false;
    } finally {
      _confirmOpen = false;
    }
    if (isClosed) return;

    if (confirmed) {
      await _submit(qrData);
    } else {
      rescan();
    }
  }

  Future<bool> _askToSubmit() async {
    final confirmWith = _confirmSubmit;
    if (confirmWith != null) return confirmWith();

    final context = Get.context;
    // No navigator to ask with: submit, as before the question existed.
    if (context == null) return true;
    return AppBottomSheet.confirm(
      context: context,
      title: 'Submit this QR code?',
      message: "We'll check the code. If it's valid, the points go to your "
          'Wallet.',
      confirmLabel: 'Submit',
      cancelLabel: 'Scan again',
      icon: Icons.qr_code_2_rounded,
    );
  }

  /// Re-arms detection and restarts the camera when it may run.
  void rescan() {
    _scanned = false;
    if (_canScan) _startScanner();
  }

  /// Re-reads the permission, then starts the camera if it may run.
  Future<void> _syncScanner() async {
    await refreshCameraStatus();
    if (_canScan) {
      _scanned = false;
      _startScanner();
    }
  }

  // ── Scanner control (serialized + guarded) ────────────────────────────────

  void _startScanner() {
    _enqueue(() async {
      if (scannerController.value.isRunning) return;
      await scannerController.start();
    });
  }

  void _stopScanner() {
    _enqueue(() async {
      if (!scannerController.value.isRunning) return;
      await scannerController.stop();
    });
  }

  void _enqueue(Future<void> Function() op) {
    _scannerOp = _scannerOp.then((_) => op()).catchError((
      Object e,
      StackTrace st,
    ) {
      log(
        'scanner op failed',
        name: 'rewardhub.qrscan',
        error: e,
        stackTrace: st,
      );
    });
  }

  Future<void> _submit(String qrData) async {
    log('Submitting QR scan', name: 'rewardhub.qrscan');
    final token = _auth.token;
    if (token == null) {
      _analytics.qrScanFailed('no_session');
      await _showResult(
        success: false,
        message: "You've been logged out, so this scan wasn't saved. "
            'Log in and scan again.',
      );
      return;
    }

    isSubmitting.value = true;
    var success = false;
    var message = '';
    try {
      final response = await _submitQrScan(
        SubmitQrScanParams(qrData: qrData, token: token),
      );
      _analytics.qrScanSucceeded(points: response.pointsEarned);

      if (Get.isRegistered<ProfileController>()) {
        final profileCtrl = Get.find<ProfileController>();
        if (response.pointsEarned != null && response.pointsEarned! > 0) {
          profileCtrl.addPoints(response.pointsEarned!);
        } else {
          profileCtrl.loadProfile(force: true);
        }
      }
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadActivities();
      }

      final earned = response.pointsEarned;
      final serverMessage = response.message?.trim() ?? '';
      success = true;
      message = (earned != null && earned > 0)
          ? 'You earned ${AppFormat.pointsWithUnit(earned)}.'
          : (serverMessage.isNotEmpty
              ? response.message!
              : 'Check Wallet to see your points.');
    } catch (e) {
      _analytics.qrScanFailed(e);
      message = resolveErrorMessage(e);
    } finally {
      // Close the "Checking code…" overlay before the result appears.
      isSubmitting.value = false;
    }

    await _showResult(success: success, message: message);
  }

  /// Shows the outcome and restarts scanning only after it's dismissed.
  Future<void> _showResult({
    required bool success,
    required String message,
  }) async {
    // Blocks resume, tab and rescan restarts while the result is open.
    _resultOpen = true;
    try {
      final presentWith = _presentResult;
      if (presentWith != null) {
        await presentWith(success: success, message: message);
      } else {
        final context = Get.context;
        if (context != null) {
          await ScanResultSheet.show(
            context,
            success: success,
            message: message,
          );
        }
      }
    } finally {
      _resultOpen = false;
    }

    rescan();
  }
}
