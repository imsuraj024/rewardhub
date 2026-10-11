import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';

/// What the KYC step does before opening the camera (DS-26).
enum KycCameraAccess {
  /// Open the camera now.
  ready,

  /// Show the in-app rationale first (once per visit).
  explain,

  /// The camera is off for this app: offer Open settings.
  blocked,
}

/// Outcome of one capture attempt (DS-27).
enum KycPickResult { added, cancelled, cameraBlocked, failed }

/// Step 3 of registration — KYC document capture (Aadhaar photo + selfie).
///
/// Picked photos are copied into app storage and their paths persisted to the
/// [RegistrationDraft] so the user can resume. The draft and the copies are
/// cleared once registration is submitted successfully.
class KycController extends GetxController {
  KycController(
    this._draftStore,
    this._auth,
    this._analytics, {
    ImagePicker? picker,
    Future<PermissionStatus> Function()? readCameraStatus,
    Future<bool> Function()? launchSettings,
    Future<Directory> Function()? photoDirectory,
  })  : _picker = picker ?? ImagePicker(),
        _readCameraStatus =
            readCameraStatus ?? (() => Permission.camera.status),
        _launchSettings = launchSettings ?? openAppSettings,
        _photoDirectory = photoDirectory ?? getApplicationSupportDirectory;

  final RegistrationDraftStore _draftStore;
  final AuthController _auth;
  final AppAnalytics _analytics;
  final ImagePicker _picker;
  final Future<PermissionStatus> Function() _readCameraStatus;
  final Future<bool> Function() _launchSettings;
  final Future<Directory> Function() _photoDirectory;

  /// The rationale was accepted on this visit (this controller's lifetime).
  bool _cameraExplained = false;

  final aadhaarPath = ''.obs;
  final selfiePath = ''.obs;

  RegistrationDraft _draft = const RegistrationDraft();

  Future<void> _prefilled = Future<void>.value();

  /// Completes once the draft has been read and checked.
  @visibleForTesting
  Future<void> get prefilled => _prefilled;

  bool get isLoading => _auth.isLoading;
  String? get errorMessage => _auth.errorMessage;

  @override
  void onInit() {
    super.onInit();
    _prefilled = _prefill();
  }

  @override
  void onReady() {
    super.onReady();
    _auth.clearError();
  }

  Future<void> _prefill() async {
    _draft = await _draftStore.read();
    aadhaarPath.value = await _usableOrEmpty(_draft.aadhaarPath);
    selfiePath.value = await _usableOrEmpty(_draft.selfiePath);
    if (aadhaarPath.value != _draft.aadhaarPath ||
        selfiePath.value != _draft.selfiePath) {
      // Saves the draft just read, with only the missing path blanked:
      // the step 1–2 fields are kept.
      await _persist();
    }
  }

  /// Reads the camera permission without ever prompting.
  ///
  /// KYC never asks permission_handler to request the camera: image_picker
  /// shows the OS prompt itself. On iOS, permission_handler's camera support
  /// is compiled out until ios/Podfile sets PERMISSION_CAMERA=1: `status`
  /// reads `denied`, and a request returns `permanentlyDenied` without asking.
  Future<KycCameraAccess> cameraAccess() async {
    var status = PermissionStatus.denied;
    try {
      status = await _readCameraStatus();
    } catch (e, st) {
      log(
        'camera status read failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
    }
    if (status.isGranted || status.isLimited) return KycCameraAccess.ready;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return KycCameraAccess.blocked;
    }
    // denied / provisional: undecided, or the OS may still ask.
    return _cameraExplained ? KycCameraAccess.ready : KycCameraAccess.explain;
  }

  /// The user tapped Continue on the rationale. Don't show it again this visit.
  void cameraExplained() => _cameraExplained = true;

  /// Opens this app's page in the phone's settings.
  Future<void> openSettings() async {
    try {
      await _launchSettings();
    } catch (e, st) {
      log(
        'open settings failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<KycPickResult> pickAadhaar(ImageSource source) =>
      _capture(KycDocument.aadhaar, source);

  Future<KycPickResult> pickSelfie() =>
      _capture(KycDocument.selfie, ImageSource.camera);

  static KycCaptureSource _sourceOf(ImageSource source) =>
      source == ImageSource.camera
          ? KycCaptureSource.camera
          : KycCaptureSource.gallery;

  /// Picker errors that mean "camera access is off": `camera_access_denied`
  /// (iOS, Android) and `camera_access_restricted` (iOS).
  static const _cameraOffCodes = {
    'camera_access_denied',
    'camera_access_restricted',
  };

  bool _capturing = false;

  Future<KycPickResult> _capture(
    KycDocument document,
    ImageSource source,
  ) async {
    // A double tap can't open two pickers.
    if (_capturing) return KycPickResult.cancelled;
    _capturing = true;
    try {
      // Never race the draft read.
      await _prefilled;
      final XFile? picked;
      try {
        picked = await _picker.pickImage(
          source: source,
          imageQuality: 70,
          maxWidth: 1600,
          preferredCameraDevice: document == KycDocument.selfie
              ? CameraDevice.front
              : CameraDevice.rear,
          // Photo metadata is never read. false keeps the gallery from ever
          // asking for Photos access, now or after a plugin update.
          requestFullMetadata: false,
        );
      } catch (e, st) {
        log(
          'image pick failed',
          name: 'rewardhub.auth',
          error: e,
          stackTrace: st,
        );
        // Every picker failure is recorded, denials included.
        _analytics.kycCaptureFailed(source: _sourceOf(source));
        if (source == ImageSource.camera &&
            e is PlatformException &&
            _cameraOffCodes.contains(e.code)) {
          // The view shows "Camera is off" (DS-26).
          return KycPickResult.cameraBlocked;
        }
        AppToast.error(
          'Please try again.',
          title: source == ImageSource.camera
              ? "Couldn't open camera"
              : "Couldn't open gallery",
        );
        return KycPickResult.failed;
      }
      // The user backed out: no toast, no event.
      if (picked == null) return KycPickResult.cancelled;

      final String kept;
      try {
        kept = await _keepPhoto(picked, document);
      } catch (e, st) {
        log(
          'keeping KYC photo failed',
          name: 'rewardhub.auth',
          error: e,
          stackTrace: st,
        );
        AppToast.error("Couldn't save this photo. Please try again.");
        return KycPickResult.failed;
      }

      final target = document == KycDocument.aadhaar ? aadhaarPath : selfiePath;
      final previous = target.value;
      target.value = kept;
      // Recorded only once the photo is kept. The path is never recorded.
      _analytics.kycDocumentCaptured(
        document: document,
        source: _sourceOf(source),
      );
      await _persist();
      await _deleteKeptPhoto(previous);
      return KycPickResult.added;
    } finally {
      _capturing = false;
    }
  }

  /// Photos picked on this step live here until registration is sent.
  /// Unlike the picker's cache, the OS doesn't clear app support storage.
  Future<Directory> _kycDirectory() async {
    final base = await _photoDirectory();
    return Directory('${base.path}/kyc_draft').create(recursive: true);
  }

  Future<String> _keepPhoto(XFile picked, KycDocument document) async {
    final dir = await _kycDirectory();
    // A fresh name for every pick: Image.file caches by path, so reusing a
    // name would keep showing the old photo.
    final target = '${dir.path}/${document.value}_'
        '${DateTime.now().microsecondsSinceEpoch}${_extensionOf(picked.path)}';
    // XFile.saveTo copies the file (cross_file io).
    await picked.saveTo(target);
    return target;
  }

  /// Keeps the picked file's extension: the upload's file name comes from
  /// the path (`MultipartFile.fromFile`, auth_remote_data_source.dart).
  /// Falls back to `.jpg`.
  static String _extensionOf(String path) {
    final name = path.substring(path.lastIndexOf('/') + 1);
    final dot = name.lastIndexOf('.');
    return (dot > 0 && dot < name.length - 1)
        ? name.substring(dot).toLowerCase()
        : '.jpg';
  }

  /// Deletes a photo this step kept earlier. A path outside kyc_draft is
  /// left alone (for example an older draft pointing into the picker cache).
  Future<void> _deleteKeptPhoto(String path) async {
    if (path.isEmpty) return;
    try {
      final dir = await _kycDirectory();
      if (!path.startsWith('${dir.path}/')) return;
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e, st) {
      log(
        'deleting old KYC photo failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _deleteAllKeptPhotos() async {
    try {
      final dir = Directory('${(await _photoDirectory()).path}/kyc_draft');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e, st) {
      log(
        'deleting KYC photos failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// A draft path is usable only while its file exists and isn't empty.
  /// On iOS the app's container path can change after an app update, so a
  /// kept photo is also looked for by name in today's kyc_draft folder.
  /// Returns the usable path (possibly the new one), or ''.
  Future<String> _usableOrEmpty(String path) async {
    if (path.isEmpty) return '';
    if (await _isUsable(path)) return path;
    final name = path.substring(path.lastIndexOf('/') + 1);
    if (!name.startsWith('aadhaar_') && !name.startsWith('selfie_')) return '';
    try {
      final moved = '${(await _kycDirectory()).path}/$name';
      return await _isUsable(moved) ? moved : '';
    } catch (_) {
      return '';
    }
  }

  static Future<bool> _isUsable(String path) async {
    try {
      final file = File(path);
      return await file.exists() && await file.length() > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persist() async {
    _draft = _draft.copyWith(
      aadhaarPath: aadhaarPath.value,
      selfiePath: selfiePath.value,
    );
    await _draftStore.save(_draft);
  }

  Future<void> onSubmit() async {
    await _prefilled;
    // A photo can disappear after it was added (storage cleared, or an
    // older draft pointing into the picker cache). Never send a dead path.
    final aadhaar = await _usableOrEmpty(aadhaarPath.value);
    final selfie = await _usableOrEmpty(selfiePath.value);
    if (aadhaar != aadhaarPath.value || selfie != selfiePath.value) {
      aadhaarPath.value = aadhaar;
      selfiePath.value = selfie;
      await _persist();
    }

    if (aadhaarPath.value.isEmpty || selfiePath.value.isEmpty) {
      _analytics.kycIncomplete(
        hasAadhaar: aadhaarPath.value.isNotEmpty,
        hasSelfie: selfiePath.value.isNotEmpty,
      );
      AppToast.warning('Add your Aadhaar photo and a selfie to continue.');
      return;
    }

    await _persist();

    await _auth.register(
      name: _draft.name,
      phone: _draft.phone,
      referralCode: _draft.referral,
      accountNumber: _draft.accountNumber,
      ifscCode: _draft.ifsc,
      upiId: _draft.upi,
      selfiePhotoPath: _draft.selfiePath,
      aadharPhotoPath: _draft.aadhaarPath,
    );

    if (_auth.errorMessage == null) {
      // AuthController.register reports the `sign_up` / `sign_up_failed` pair;
      // this step event closes the registration funnel.
      _analytics.registrationStepCompleted(RegistrationStep.kyc);
      AppToast.success('Your details were submitted for verification.');
      await _draftStore.clear();
      // The photos were sent, so no copies stay on the phone.
      await _deleteAllKeptPhotos();
      // Registration is done: Login replaces the whole stack.
      Get.offAllNamed(AppRoutes.login);
    } else {
      // The draft and photos are kept for a retry.
      AppToast.error(_auth.errorMessage!);
    }
  }
}
