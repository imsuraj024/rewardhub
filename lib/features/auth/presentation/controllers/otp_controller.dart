import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';

/// Screen controller for the OTP verification form.
///
/// Manages the six digit boxes, the resend countdown, and delegates
/// verification to [AuthController].
class OtpController extends GetxController {
  OtpController({
    required this.phone,
    required AuthController auth,
    required AppAnalytics analytics,
  })  : _auth = auth,
        _analytics = analytics;

  final String phone;
  final AuthController _auth;
  final AppAnalytics _analytics;

  static const otpLength = 6;
  static const timerDuration = 5 * 60;

  final List<TextEditingController> controllers = List.generate(
    otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(
    otpLength,
    (_) => FocusNode(),
  );

  final remainingSeconds = timerDuration.obs;
  final canResend = false.obs;
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  void startTimer() {
    remainingSeconds.value = timerDuration;
    canResend.value = false;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isDisposed) return false;
      remainingSeconds.value--;
      if (remainingSeconds.value <= 0) canResend.value = true;
      return remainingSeconds.value > 0;
    });
  }

  @override
  void onClose() {
    _isDisposed = true;
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.onClose();
  }

  String get otp => controllers.map((c) => c.text).join();

  String get maskedPhone {
    final p = phone;
    if (p.length < 4) return p;
    final visible = p.substring(p.length - 2);
    return '${p.substring(0, p.length > 4 ? 4 : 0)} • •••$visible';
  }

  String get timerLabel {
    final m = (remainingSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void onDigitChanged(int index, String value) {
    if (value.length == 1 && index < otpLength - 1) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> onVerify() async {
    final currentOtp = otp;
    if (currentOtp.length < otpLength) {
      _analytics.otpIncomplete(digitsEntered: currentOtp.length);
      AppToast.warning('Please enter all 6 digits');
      return;
    }
    if (_isDisposed) return;

    // AuthController.verifyOtp navigates to the shell on success.
    await _auth.verifyOtp(currentOtp);
  }

  Future<void> onResend() async {
    if (!canResend.value || _isDisposed) return;
    await _auth.login(phone);
    if (_isDisposed) return;
    if (_auth.errorMessage != null) {
      AppToast.error(_auth.errorMessage!);
      return;
    }
    for (final c in controllers) {
      c.clear();
    }
    focusNodes[0].requestFocus();
    startTimer();
    _analytics.otpRequested(isResend: true);
    AppToast.success('A new code has been sent to your phone.');
  }
}
