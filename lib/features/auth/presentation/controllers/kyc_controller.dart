import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';

/// Step 3 of registration — KYC document capture (Aadhaar photo + selfie).
///
/// Image paths are persisted to the [RegistrationDraft] as they are picked so
/// the user can resume, and the whole draft is cleared once registration is
/// submitted successfully.
class KycController extends GetxController {
  KycController(this._draftStore, this._auth, this._analytics);

  final RegistrationDraftStore _draftStore;
  final AuthController _auth;
  final AppAnalytics _analytics;
  final _picker = ImagePicker();

  final aadhaarPath = ''.obs;
  final selfiePath = ''.obs;

  RegistrationDraft _draft = const RegistrationDraft();

  bool get isLoading => _auth.isLoading;
  String? get errorMessage => _auth.errorMessage;

  @override
  void onInit() {
    super.onInit();
    _prefill();
  }

  @override
  void onReady() {
    super.onReady();
    _auth.clearError();
  }

  Future<void> _prefill() async {
    _draft = await _draftStore.read();
    aadhaarPath.value = _draft.aadhaarPath;
    selfiePath.value = _draft.selfiePath;
  }

  Future<void> pickAadhaar(ImageSource source) async {
    final path = await _pick(source);
    if (path == null) return;
    aadhaarPath.value = path;
    // The document and its source are recorded; the file path never is.
    _analytics.kycDocumentCaptured(
      document: KycDocument.aadhaar,
      source: _sourceOf(source),
    );
    await _persist();
  }

  Future<void> pickSelfie() async {
    final path = await _pick(ImageSource.camera, preferFront: true);
    if (path == null) return;
    selfiePath.value = path;
    _analytics.kycDocumentCaptured(
      document: KycDocument.selfie,
      source: KycCaptureSource.camera,
    );
    await _persist();
  }

  static KycCaptureSource _sourceOf(ImageSource source) =>
      source == ImageSource.camera
          ? KycCaptureSource.camera
          : KycCaptureSource.gallery;

  Future<String?> _pick(ImageSource source, {bool preferFront = false}) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
        preferredCameraDevice: preferFront
            ? CameraDevice.front
            : CameraDevice.rear,
      );
      return file?.path;
    } catch (e, st) {
      log(
        'image pick failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
      _analytics.kycCaptureFailed(source: _sourceOf(source));
      AppToast.error(
        'Allow access in your phone settings, then try again.',
        title: source == ImageSource.camera
            ? "Couldn't open camera"
            : "Couldn't open gallery",
      );
      return null;
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
      // Registration is done: Login replaces the whole stack.
      Get.offAllNamed(AppRoutes.login);
    } else {
      AppToast.error(_auth.errorMessage!);
    }
  }
}
