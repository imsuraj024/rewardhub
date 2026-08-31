import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';

/// Screen controller for the login form.
///
/// Owns the form's input state and delegates the auth action to
/// [AuthController].
class LoginController extends GetxController {
  LoginController(this._auth, this._analytics);

  final AuthController _auth;
  final AppAnalytics _analytics;

  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();

  @override
  void onReady() {
    super.onReady();
    _auth.clearError();
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  Future<void> onContinue() async {
    if (!formKey.currentState!.validate()) return;
    final phone = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');

    await _auth.login(phone);

    if (_auth.errorMessage != null) {
      // AuthController already reported why.
      AppToast.error(_auth.errorMessage!);
      return;
    }

    if (_auth.isNewUser) {
      Get.toNamed(AppRoutes.register);
    } else {
      _analytics.otpRequested(isResend: false);
      Get.offAllNamed(AppRoutes.shell);
    }
  }
}
