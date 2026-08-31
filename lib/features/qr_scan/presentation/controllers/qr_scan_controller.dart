import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/error_message.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/qr_scan/domain/usecases/submit_qr_scan_usecase.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';

/// Surfaces the outcome of a submitted scan to the user.
///
/// Injectable so tests can capture outcomes without a live toast overlay.
typedef ScanResultPresenter =
    void Function({required bool success, required String message});

/// Drives the QR scanner: camera permission, the scanner lifecycle (tied to the
/// active shell tab and the app lifecycle), and submitting scanned codes.
///
/// The [MobileScanner] widget stays mounted for the lifetime of the QR tab; the
/// camera is opened/closed purely via [_startScanner]/[_stopScanner]. Those are
/// serialized and guarded with [MobileScannerController.value.isRunning] so
/// overlapping tab/lifecycle events can never leave the camera in a bad state
/// (the cause of the "camera stops working" intermittent freeze).
class QrScanController extends GetxController with WidgetsBindingObserver {
  QrScanController({
    required SubmitQrScanUseCase submitQrScan,
    required AuthController authController,
    required ShellController shellController,
    required AppAnalytics analytics,
    ScanResultPresenter? presentResult,
  }) : _submitQrScan = submitQrScan,
       _auth = authController,
       _shell = shellController,
       _analytics = analytics,
       _presentResult = presentResult;

  final SubmitQrScanUseCase _submitQrScan;
  final AuthController _auth;
  final ShellController _shell;
  final AppAnalytics _analytics;

  /// Overrides how a scan outcome is surfaced.
  ///
  /// The default is an [AppToast], which requires a live overlay — something
  /// a pure-Dart controller test does not have. Tests pass a recorder here
  /// instead of having to pump a whole app. `null` in production.
  final ScanResultPresenter? _presentResult;

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

  /// Serializes scanner start/stop calls so they never overlap.
  Future<void> _scannerOp = Future<void>.value();

  bool get _isOnQrTab => _shell.currentIndex.value == qrTabIndex;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    requestCameraPermission();

    // Scan only while the QR tab is active.
    _tabWorker = ever<int>(_shell.currentIndex, (index) {
      if (!cameraStatus.value.isGranted) return;
      if (index == qrTabIndex) {
        _scanned = false;
        _startScanner();
      } else {
        _stopScanner();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!cameraStatus.value.isGranted || !_isOnQrTab) return;
    if (state == AppLifecycleState.resumed) {
      _scanned = false;
      _startScanner();
    } else if (state == AppLifecycleState.inactive ||
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

  Future<void> requestCameraPermission() async {
    cameraStatus.value = await Permission.camera.request();
    // The gate on the entire scanning feature — worth measuring on its own.
    _analytics.cameraPermissionResult(granted: cameraStatus.value.isGranted);
    // If permission is granted while the QR tab is already showing, the tab
    // worker won't fire again — start the scanner here.
    if (cameraStatus.value.isGranted && _isOnQrTab) {
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
    _submit(barcode.rawValue!);
  }

  void rescan() {
    _scanned = false;
    _startScanner();
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
      _showResult(
        success: false,
        message: 'Session expired. Please log in again.',
      );
      return;
    }

    isSubmitting.value = true;
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

      _showResult(
        success: true,
        message: response.pointsEarned != null
            ? 'You earned ${response.pointsEarned} pts!'
            : response.message ?? 'Points added successfully!',
      );
    } catch (e) {
      _analytics.qrScanFailed(e);
      _showResult(success: false, message: resolveErrorMessage(e));
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showResult({required bool success, required String message}) {
    final presentWith = _presentResult;
    if (presentWith != null) {
      presentWith(success: success, message: message);
    } else {
      if (success) {
        AppToast.success(message);
      } else {
        AppToast.error(message);
      }
    }

    rescan();
  }
}
