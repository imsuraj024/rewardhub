import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/error_message.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/wallet/domain/usecases/raise_wallet_request_usecase.dart';

/// Drives wallet actions triggered from the dashboard (currently the
/// "Redeem" quick action, which raises a redemption request).
class WalletController extends GetxController {
  WalletController({
    required AuthController authController,
    required RaiseWalletRequestUseCase raiseWalletRequest,
    required AppAnalytics analytics,
  })  : _auth = authController,
        _raiseWalletRequest = raiseWalletRequest,
        _analytics = analytics;

  final AuthController _auth;
  final RaiseWalletRequestUseCase _raiseWalletRequest;
  final AppAnalytics _analytics;

  final isSubmitting = false.obs;

  /// Submits a `/wallet/raise-request` for the current session and surfaces
  /// the outcome via a toast. Guarded against overlapping taps.
  Future<void> raiseRequest() async {
    if (isSubmitting.value) return;

    _analytics.redeemRequested();

    final token = _auth.token;
    if (token == null || token.isEmpty) {
      _analytics.redeemFailed('no_session');
      AppToast.error('Session expired. Please log in again.');
      return;
    }

    isSubmitting.value = true;
    try {
      final response = await _raiseWalletRequest(token);
      _analytics.redeemSucceeded();
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().loadProfile(force: true);
      }
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadActivities();
      }
      AppToast.success(response.message ?? 'Your request has been raised.');
    } catch (e, st) {
      _analytics.redeemFailed(e);
      log('raiseRequest failed',
          name: 'rewardhub.wallet', error: e, stackTrace: st);
      AppToast.error(resolveErrorMessage(e));
    } finally {
      isSubmitting.value = false;
    }
  }
}
