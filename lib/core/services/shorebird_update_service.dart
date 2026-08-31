import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/core/widgets/shorebird_update_dialog.dart';

/// Service responsible for managing Shorebird Code Push over-the-air (OTA)
/// updates and prompting the user when a new patch is available.
class ShorebirdUpdateService extends GetxService {
  ShorebirdUpdateService({
    ShorebirdUpdater? updater,
    Future<void> Function()? restartHandler,
  })  : _updater = updater ?? ShorebirdUpdater(),
        _restartHandler = restartHandler ?? _defaultRestartApp;

  final ShorebirdUpdater _updater;
  final Future<void> Function() _restartHandler;

  final _isChecking = false.obs;
  final _isDownloading = false.obs;
  final _isRestartRequired = false.obs;
  final _hasUpdateAvailable = false.obs;
  final _currentPatch = Rxn<Patch>();

  bool get isChecking => _isChecking.value;
  bool get isDownloading => _isDownloading.value;
  bool get isRestartRequired => _isRestartRequired.value;
  bool get hasUpdateAvailable => _hasUpdateAvailable.value;
  Patch? get currentPatch => _currentPatch.value;
  int? get currentPatchNumber => _currentPatch.value?.number;

  /// Whether Shorebird code push is supported on the current runtime/build.
  bool get isAvailable => _updater.isAvailable;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentPatch();
  }

  Future<void> _loadCurrentPatch() async {
    try {
      if (isAvailable) {
        final patch = await _updater.readCurrentPatch();
        _currentPatch.value = patch;
      }
    } catch (e, st) {
      log(
        'Failed to read current patch',
        name: 'rewardhub.shorebird',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Checks Shorebird servers for a new patch.
  ///
  /// Set [isManual] to true when the check is explicitly triggered by the user
  /// (e.g. from the Profile screen) to display feedback toast messages.
  Future<void> checkForUpdates({bool isManual = false}) async {
    if (_isChecking.value || _isDownloading.value) return;

    _isChecking.value = true;
    try {
      if (!isAvailable) {
        log(
          'Shorebird updater is not available on this platform/build',
          name: 'rewardhub.shorebird',
        );
        if (isManual) {
          AppToast.info(
            'Shorebird code push is not active in this build.',
            title: 'Updates',
          );
        }
        return;
      }

      final status = await _updater.checkForUpdate();
      log('Shorebird update status: $status', name: 'rewardhub.shorebird');

      switch (status) {
        case UpdateStatus.outdated:
          _hasUpdateAvailable.value = true;
          showUpdateDialog(isRestartReady: false);
        case UpdateStatus.restartRequired:
          _isRestartRequired.value = true;
          _hasUpdateAvailable.value = false;
          showUpdateDialog(isRestartReady: true);
        case UpdateStatus.upToDate:
          _hasUpdateAvailable.value = false;
          if (isManual) {
            AppToast.info(
              'You are on the latest version.',
              title: 'Up to Date',
            );
          }
        case UpdateStatus.unavailable:
          _hasUpdateAvailable.value = false;
          if (isManual) {
            AppToast.info(
              'No updates are available right now.',
              title: 'Up to Date',
            );
          }
      }
    } catch (e, st) {
      log(
        'Error checking for Shorebird updates',
        name: 'rewardhub.shorebird',
        error: e,
        stackTrace: st,
      );
      if (isManual) {
        AppToast.error(
          'Could not check for updates. Please try again later.',
          title: 'Update Error',
        );
      }
    } finally {
      _isChecking.value = false;
    }
  }

  /// Downloads the available patch from Shorebird and transitions to restart-ready.
  Future<bool> downloadAndApplyUpdate() async {
    if (_isDownloading.value) return false;

    _isDownloading.value = true;
    try {
      await _updater.update();
      _isRestartRequired.value = true;
      _hasUpdateAvailable.value = false;
      return true;
    } catch (e, st) {
      log(
        'Failed to download Shorebird update',
        name: 'rewardhub.shorebird',
        error: e,
        stackTrace: st,
      );
      AppToast.error(
        'Failed to download the update. Please check your connection and try again.',
        title: 'Update Failed',
      );
      return false;
    } finally {
      _isDownloading.value = false;
    }
  }

  /// Restarts the application using the native restart mechanism.
  Future<void> restartApp() async {
    try {
      await _restartHandler();
    } catch (e, st) {
      log(
        'Failed to restart app',
        name: 'rewardhub.shorebird',
        error: e,
        stackTrace: st,
      );
      AppToast.info(
        'Please close and reopen the app to apply the update.',
        title: 'Restart App',
      );
    }
  }

  /// Checks for updates on app launch. If an update is available, displays the
  /// update popup and waits until the user acts/dismisses it before continuing.
  /// If no update is available (or on error/timeout), returns false immediately so
  /// the app launch sequence continues without delay.
  Future<bool> checkUpdateOnLaunch({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!isAvailable) return false;

    try {
      final status = await _updater
          .checkForUpdate()
          .timeout(timeout, onTimeout: () => UpdateStatus.unavailable);

      log('Shorebird launch check status: $status', name: 'rewardhub.shorebird');

      switch (status) {
        case UpdateStatus.outdated:
          _hasUpdateAvailable.value = true;
          await showUpdateDialog(isRestartReady: false);
          return true;
        case UpdateStatus.restartRequired:
          _isRestartRequired.value = true;
          _hasUpdateAvailable.value = false;
          await showUpdateDialog(isRestartReady: true);
          return true;
        case UpdateStatus.upToDate:
        case UpdateStatus.unavailable:
          _hasUpdateAvailable.value = false;
          return false;
      }
    } catch (e, st) {
      log(
        'Shorebird launch check failed or timed out',
        name: 'rewardhub.shorebird',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Optional dialog presenter override for unit testing.
  @visibleForTesting
  Future<void> Function({bool isRestartReady})? dialogPresenter;

  /// Displays the update modal dialog.
  Future<void> showUpdateDialog({bool isRestartReady = false}) async {
    final presentWith = dialogPresenter;
    if (presentWith != null) {
      await presentWith(isRestartReady: isRestartReady);
      return;
    }

    if (Get.testMode) return;
    if (Get.isDialogOpen ?? false) return;

    await Get.dialog(
      ShorebirdUpdateDialog(
        service: this,
        initialRestartReady: isRestartReady,
      ),
      barrierDismissible: false,
    );
  }

  static Future<void> _defaultRestartApp() async {
    if (kIsWeb) return;
    await Restart.restartApp();
  }
}
