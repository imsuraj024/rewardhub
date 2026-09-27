import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/network/error_messages.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/error_message.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/features/auth/domain/usecases/login_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/logout_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/register_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/verify_otp_usecase.dart';

/// Owns the app-wide authentication state and session lifecycle.
///
/// Registered as a permanent singleton so any feature can read the current
/// [token] / [isAuthenticated] flag. Screen-level controllers delegate their
/// auth actions here.
class AuthController extends GetxController {
  AuthController({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
    required LogoutUseCase logoutUseCase,
    DeleteAccountUseCase? deleteAccountUseCase,
    required AppAnalytics analytics,
  }) : _login = loginUseCase,
       _register = registerUseCase,
       _verifyOtp = verifyOtpUseCase,
       _restoreSession = restoreSessionUseCase,
       _logout = logoutUseCase,
       _deleteAccount = deleteAccountUseCase,
       _analytics = analytics;

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final VerifyOtpUseCase _verifyOtp;
  final RestoreSessionUseCase _restoreSession;
  final LogoutUseCase _logout;
  final DeleteAccountUseCase? _deleteAccount;
  final AppAnalytics _analytics;

  final _isAuthenticated = false.obs;
  final _isNewUser = false.obs;
  final _isSessionRestored = false.obs;
  final _token = Rxn<String>();
  final _isLoading = false.obs;
  final _errorMessage = Rxn<String>();

  bool get isAuthenticated => _isAuthenticated.value;
  bool get isNewUser => _isNewUser.value;
  bool get isSessionRestored => _isSessionRestored.value;
  String? get token => _token.value;

  /// Reactive session token. Emits when the token is set (login/session
  /// restore) or cleared (logout), letting dependents load data as soon as a
  /// session is available regardless of construction order.
  Rxn<String> get tokenListenable => _token;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  // ── Session ─────────────────────────────────────────────────────────────

  Future<void> restoreSession() async {
    try {
      final token = await _restoreSession(const NoParams());
      if (token != null) {
        _token.value = token;
        _isAuthenticated.value = true;
      }
    } catch (e, st) {
      log(
        'restoreSession failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
    } finally {
      _isSessionRestored.value = true;
    }

    if (Get.isRegistered<RemoteConfigService>()) {
      final remoteConfig = Get.find<RemoteConfigService>();
      if (remoteConfig.isMaintenanceMode) {
        Get.offAllNamed(AppRoutes.maintenance);
        return;
      }
      if (remoteConfig.latestVersion.isNotEmpty) {
        try {
          final packageInfo = await PackageInfo.fromPlatform();
          if (isVersionOutdated(packageInfo.version, remoteConfig.latestVersion)) {
            Get.offAllNamed(AppRoutes.appUpdate);
            return;
          }
        } catch (e, st) {
          log(
            'Failed to read app package version',
            name: 'rewardhub.auth',
            error: e,
            stackTrace: st,
          );
        }
      }
    }

    if (Get.isRegistered<ShorebirdUpdateService>()) {
      await Get.find<ShorebirdUpdateService>().checkUpdateOnLaunch();
    }

    Get.offAllNamed(_isAuthenticated.value ? AppRoutes.shell : AppRoutes.login);
  }

  // ── Public API ──────────────────────────────────────────────────────────

  void clearError() => _errorMessage.value = null;

  Future<void> login(String phone) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      final response = await _login(phone);
      _isNewUser.value = response.isNewUser;
      if (response.success) {
        _token.value = response.token;
      } else if (!response.isNewUser) {
        _errorMessage.value =
            response.message ??
            "Couldn't log you in. Check your number and try again.";
        // Refused by the server rather than a transport failure.
        _analytics.loginFailed('rejected');
      }
      if (response.isNewUser) _analytics.registrationStarted();
    } catch (e, st) {
      _errorMessage.value = resolveErrorMessage(e);
      _analytics.loginFailed(e);
      log('login failed', name: 'rewardhub.auth', error: e, stackTrace: st);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String referralCode,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    String? selfiePhotoPath,
    String? aadharPhotoPath,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      final response = await _register(
        RegisterParams(
          name: name,
          phone: phone,
          referralCode: referralCode,
          accountNumber: accountNumber,
          ifscCode: ifscCode,
          upiId: upiId,
          selfiePhotoPath: selfiePhotoPath,
          aadharPhotoPath: aadharPhotoPath,
        ),
      );
      _token.value = response.token;
      _analytics.signUpSucceeded();
    } catch (e, st) {
      _errorMessage.value = resolveErrorMessage(e);
      _analytics.signUpFailed(e);
      log('register failed', name: 'rewardhub.auth', error: e, stackTrace: st);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (_token.value == null) {
      _errorMessage.value = ErrorMessages.sessionExpired;
      _analytics.otpVerificationFailed('no_session');
      return;
    }
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      await _verifyOtp(VerifyOtpParams(token: _token.value!, otp: otp));
      _isAuthenticated.value = true;
      // The session is live only now, so this is where GA4's reserved `login`
      // belongs — not at the point the OTP was requested.
      _analytics.loginSucceeded();
      Get.offAllNamed(AppRoutes.shell);
    } catch (e, st) {
      _errorMessage.value = resolveErrorMessage(e);
      _analytics.otpVerificationFailed(e);
      log('verifyOtp failed', name: 'rewardhub.auth', error: e, stackTrace: st);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _logout(const NoParams());
    _analytics.logout();
    _analytics.clearIdentity();
    _token.value = null;
    _isAuthenticated.value = false;
    _isNewUser.value = false;
    _errorMessage.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  Future<bool> deleteAccount() async {
    if (_token.value == null) return false;
    _isLoading.value = true;
    _errorMessage.value = null;
    try {
      final deleteAccount = _deleteAccount;
      if (deleteAccount != null) {
        await deleteAccount(_token.value!);
      }
      _token.value = null;
      _isAuthenticated.value = false;
      _isNewUser.value = false;
      _analytics.logout();
      _analytics.clearIdentity();
      return true;
    } catch (e, st) {
      log(
        'deleteAccount failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
      _errorMessage.value = resolveErrorMessage(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Handles a session the server has rejected (HTTP 401).
  ///
  /// Wired to `ApiClient.setUnauthenticatedHandler` in `InitialBinding`.
  /// `AuthInterceptor` has already dropped the stored token by the time this
  /// runs — it just has no way to navigate — so this clears the in-memory
  /// session and sends the user back to login. Without it an expired token
  /// leaves the user sitting on an authenticated screen where every request
  /// silently fails.
  ///
  /// Guarded on [isAuthenticated] because several requests can be in flight and
  /// each can come back 401; the first call wins and the rest are no-ops, so the
  /// user gets one message and one redirect. The guard re-arms on the next
  /// successful login or session restore.
  void handleSessionExpired() {
    if (!_isAuthenticated.value) return;

    _token.value = null;
    _isAuthenticated.value = false;
    _isNewUser.value = false;
    _errorMessage.value = null;

    _analytics.sessionExpired();
    _analytics.clearIdentity();

    AppToast.warning(ErrorMessages.sessionExpired);
    Get.offAllNamed(AppRoutes.login);
  }

  /// Compares [currentVersion] (e.g., "1.0.0+4" or "1.0.0") against [latestVersion]
  /// (e.g., "1.1.0") to determine if the installed app version is outdated.
  static bool isVersionOutdated(String currentVersion, String latestVersion) {
    final latestClean = latestVersion.split('+').first.trim();
    if (latestClean.isEmpty) return false;

    final currentClean = currentVersion.split('+').first.trim();

    final currentParts =
        currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts =
        latestClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength =
        currentParts.length > latestParts.length
            ? currentParts.length
            : latestParts.length;

    for (int i = 0; i < maxLength; i++) {
      final currentNum = i < currentParts.length ? currentParts[i] : 0;
      final latestNum = i < latestParts.length ? latestParts[i] : 0;

      if (currentNum < latestNum) return true;
      if (currentNum > latestNum) return false;
    }

    return false;
  }
}
