import 'package:rewardhub/core/analytics/i_analytics_service.dart';
import 'package:rewardhub/core/network/api_exception.dart';

/// Every event this app reports, as typed methods.
///
/// This is the **only** place event and parameter names are written. Call sites
/// call `analytics.qrScanSucceeded(points: 25)` rather than assembling a map, so
/// a name can never be misspelled in one screen and correct in another, and the
/// whole taxonomy can be reviewed by reading this one file.
///
/// ## Rules this class enforces
///
/// * **No personal data, ever.** Phone numbers, names, OTPs, Aadhaar or selfie
///   paths, UPI IDs, account numbers, IFSC codes and session tokens must never
///   reach an event. Sending them would breach the Firebase terms and put KYC
///   data in a third-party analytics store. That is why methods here take
///   booleans, enums and counts — never free-form user input. The only
///   identifier used is the server's opaque profile id (see [identify]).
/// * **Bounded cardinality.** Failure reasons are mapped to a small fixed set
///   by [_reasonFor] instead of forwarding raw server messages, which would
///   both explode GA4's cardinality and risk leaking response contents.
/// * **GA4 limits.** Event names are snake_case and <= 40 chars; string values
///   are truncated to 100 chars by [_str]; user property values to 36.
///
/// GA4's own reserved events (`login`, `sign_up`, `screen_view`,
/// `select_content`) are used where they fit, because Firebase reports on them
/// natively; everything else is a custom event.
class AppAnalytics {
  const AppAnalytics(this._service);

  final IAnalyticsService _service;

  // GA4 caps a string parameter at 100 chars and a user property at 36.
  static const int _maxParamLength = 100;
  static const int _maxUserPropertyLength = 36;

  /// The one login method this app supports.
  static const String _methodPhone = 'phone';

  // ── Identity ──────────────────────────────────────────────────────────────

  /// Ties subsequent events to the signed-in user.
  ///
  /// [profileId] is the server's opaque profile identifier — deliberately not
  /// the phone number, which is the only other id available and is personal
  /// data.
  Future<void> identify(String profileId) {
    if (profileId.isEmpty) return Future<void>.value();
    return _service.setUserId(profileId);
  }

  /// Drops the identity and locally held data. Called on logout so a shared
  /// device does not attribute the next user's events to the previous one.
  Future<void> clearIdentity() async {
    await _service.setUserId(null);
    await _service.reset();
  }

  /// Records how the user chose to be paid, for segmentation.
  ///
  /// Records only *which kind* of payout was configured, never the values.
  Future<void> setPayoutMethod({
    required bool hasUpi,
    required bool hasBank,
  }) {
    final value = switch ((hasUpi, hasBank)) {
      (true, true) => 'upi_and_bank',
      (true, false) => 'upi',
      (false, true) => 'bank',
      (false, false) => 'none',
    };
    return _service.setUserProperty(
      name: 'payout_method',
      value: _str(value, _maxUserPropertyLength),
    );
  }

  // ── Screens ───────────────────────────────────────────────────────────────

  /// Logs a screen the route observer cannot see.
  ///
  /// The shell's tabs live in an `IndexedStack` behind a single `/shell` route,
  /// so switching tabs pushes no route and fires no automatic `screen_view`.
  Future<void> screenView(String screenName) =>
      _service.logScreenView(screenName: _str(screenName));

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// An OTP was requested — the first step of the login funnel.
  Future<void> otpRequested({required bool isResend}) => _service.logEvent(
        'otp_requested',
        {'is_resend': isResend},
      );

  /// The user pressed Verify without filling all six digits.
  Future<void> otpIncomplete({required int digitsEntered}) =>
      _service.logEvent('otp_incomplete', {'digits_entered': digitsEntered});

  /// OTP verification failed. [error] is mapped to a coarse reason.
  Future<void> otpVerificationFailed(Object? error) => _service.logEvent(
        'otp_verification_failed',
        {'reason': _reasonFor(error)},
      );

  /// Login succeeded. Uses GA4's reserved `login` event.
  Future<void> loginSucceeded() => _service.logLogin(method: _methodPhone);

  /// Login failed before a session was established.
  Future<void> loginFailed(Object? error) =>
      _service.logEvent('login_failed', {'reason': _reasonFor(error)});

  /// The phone number was recognised as new, sending the user to registration.
  Future<void> registrationStarted() =>
      _service.logEvent('registration_started');

  /// A registration step was completed. [step] is one of the [RegistrationStep]
  /// values, giving a clean funnel from personal details through to KYC.
  Future<void> registrationStepCompleted(RegistrationStep step) =>
      _service.logEvent(
        'registration_step_completed',
        {'step': step.value},
      );

  /// The user tried to advance past step 1 without accepting the terms.
  Future<void> termsNotAccepted() => _service.logEvent('terms_not_accepted');

  /// The user opened the optional bank-details section — an intent signal for
  /// how people prefer to be paid.
  Future<void> bankDetailsRevealed() =>
      _service.logEvent('bank_details_revealed');

  /// A KYC document was captured. Records *which* document and *where from*,
  /// never the file path.
  Future<void> kycDocumentCaptured({
    required KycDocument document,
    required KycCaptureSource source,
  }) =>
      _service.logEvent('kyc_document_captured', {
        'document': document.value,
        'source': source.value,
      });

  /// The camera/gallery picker could not be opened.
  Future<void> kycCaptureFailed({required KycCaptureSource source}) =>
      _service.logEvent('kyc_capture_failed', {'source': source.value});

  /// The user pressed Submit on KYC without both documents present.
  Future<void> kycIncomplete({
    required bool hasAadhaar,
    required bool hasSelfie,
  }) =>
      _service.logEvent('kyc_incomplete', {
        'has_aadhaar': hasAadhaar,
        'has_selfie': hasSelfie,
      });

  /// Registration was submitted successfully. Uses GA4's reserved `sign_up`.
  Future<void> signUpSucceeded() => _service.logSignUp(method: _methodPhone);

  /// Registration submission failed.
  Future<void> signUpFailed(Object? error) =>
      _service.logEvent('sign_up_failed', {'reason': _reasonFor(error)});

  /// The user logged out deliberately.
  Future<void> logout() => _service.logEvent('logout');

  /// The server rejected the session (401) and the user was bounced to login.
  /// Distinct from [logout] so involuntary exits can be measured separately.
  Future<void> sessionExpired() => _service.logEvent('session_expired');

  // ── QR scanning (the app's core action) ────────────────────────────────────

  /// Result of the camera permission prompt — the gate on the whole feature.
  Future<void> cameraPermissionResult({required bool granted}) =>
      _service.logEvent('camera_permission_result', {'granted': granted});

  /// A code was decoded and is about to be submitted. The payload itself is
  /// deliberately not recorded.
  Future<void> qrCodeDetected() => _service.logEvent('qr_code_detected');

  /// A scan was accepted. [points] is omitted when the response carried none.
  Future<void> qrScanSucceeded({int? points}) => _service.logEvent(
        'qr_scan_succeeded',
        points != null ? {'points_earned': points} : null,
      );

  /// A scan was rejected, either by the server or by a missing session.
  Future<void> qrScanFailed(Object? error) =>
      _service.logEvent('qr_scan_failed', {'reason': _reasonFor(error)});

  /// The user tapped "Scan Again" on the result snackbar.
  Future<void> qrRescanTapped() => _service.logEvent('qr_rescan_tapped');

  // ── Wallet ────────────────────────────────────────────────────────────────

  /// The user asked to redeem their points.
  Future<void> redeemRequested() => _service.logEvent('redeem_requested');

  Future<void> redeemSucceeded() => _service.logEvent('redeem_succeeded');

  Future<void> redeemFailed(Object? error) =>
      _service.logEvent('redeem_failed', {'reason': _reasonFor(error)});

  // ── Navigation & engagement ───────────────────────────────────────────────

  /// A bottom-navigation tab was selected.
  Future<void> tabSelected(String tabName) =>
      _service.logEvent('tab_selected', {'tab_name': _str(tabName)});

  /// A named piece of UI was tapped. Uses GA4's reserved `select_content` so
  /// these show up in Firebase's built-in engagement reports.
  Future<void> quickActionTapped(String action) => _service.logSelectContent(
        contentType: 'quick_action',
        itemId: _str(action),
      );

  /// An FAQ question was expanded — the clearest signal of what confuses users.
  ///
  /// [question] is static app copy, not user input, so it is safe to record and
  /// its cardinality is bounded by the number of questions shipped.
  Future<void> faqQuestionExpanded(String question) =>
      _service.logEvent('faq_question_expanded', {
        'faq_question': _str(question),
      });

  /// A row in the profile screen's settings list was tapped.
  Future<void> settingsItemTapped(String item) => _service.logSelectContent(
        contentType: 'settings_item',
        itemId: _str(item),
      );

  /// The support address was copied — a proxy for unresolved problems.
  Future<void> supportEmailCopied() =>
      _service.logEvent('support_email_copied');

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Collapses a failure into one of a small, fixed set of reasons.
  ///
  /// Raw server messages are never used: they are unbounded (destroying GA4's
  /// usefulness once the 500-value cardinality limit is hit) and could contain
  /// response details that do not belong in analytics.
  ///
  /// A [String] is taken as an already-mapped reason, so a call site that knows
  /// the exact cause — a login the server refused, an action attempted with no
  /// session — can state it without inventing an exception to describe it.
  static String _reasonFor(Object? error) => switch (error) {
        null => 'unknown',
        String reason => _str(reason, _maxUserPropertyLength),
        NoInternetException() => 'no_internet',
        UnauthorizedException() => 'unauthorized',
        ValidationException() => 'validation',
        ServerException() => 'server',
        NetworkException() => 'no_internet',
        ApiException() => 'api',
        _ => 'unknown',
      };

  /// Truncates a string to GA4's limit so an over-long value is shortened
  /// rather than dropped by the SDK.
  static String _str(String value, [int max = _maxParamLength]) =>
      value.length <= max ? value : value.substring(0, max);
}

/// The three steps of the registration funnel.
///
/// Each carries its own wire [value] rather than relying on `Enum.name`, which
/// would put camelCase (`personalDetails`) into GA4 and would silently change
/// the reported value if the Dart constant were ever renamed.
enum RegistrationStep {
  personalDetails('personal_details'),
  accountDetails('account_details'),
  kyc('kyc');

  const RegistrationStep(this.value);

  /// The value sent to GA4.
  final String value;
}

/// The KYC documents the user must provide.
enum KycDocument {
  aadhaar('aadhaar'),
  selfie('selfie');

  const KycDocument(this.value);

  /// The value sent to GA4.
  final String value;
}

/// Where a KYC image came from.
enum KycCaptureSource {
  camera('camera'),
  gallery('gallery');

  const KycCaptureSource(this.value);

  /// The value sent to GA4.
  final String value;
}
