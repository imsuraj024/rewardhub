import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/phone_input_formatter.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/login_controller.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_header.dart';
import 'package:rewardhub/features/auth/presentation/widgets/validated_text_field.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8EDF8), Color(0xFFD6E0F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const AuthHeader(
                        title: AppStrings.productName,
                        subtitle: 'Scan, earn, and redeem rewards every day.',
                      ),
                      const SizedBox(height: 32),
                      AuthFormCard(
                        child: Form(
                          key: controller.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back',
                                style: AppTextStyles.headlineSm,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter your mobile number to continue.',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 28),
                              ValidatedTextField(
                                label: 'MOBILE NUMBER',
                                controller: controller.phoneController,
                                keyboardType: TextInputType.phone,
                                autofocus: true,
                                inputFormatters: [PhoneInputFormatter()],
                                hintText: '98765 43210',
                                prefixIcon: const Icon(
                                  Icons.phone_android_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Mobile number is required';
                                  }
                                  final digits = v.trim().replaceAll(
                                    RegExp(r'\D'),
                                    '',
                                  );
                                  if (digits.length != 10) {
                                    return 'Enter a valid 10-digit mobile number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Primary CTA docks here, staying just above the keyboard.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(
                      () => AppButton(
                        label: 'Continue',
                        onPressed: auth.isLoading
                            ? null
                            : controller.onContinue,
                        isLoading: auth.isLoading,
                        isFullWidth: true,
                        size: AppButtonSize.lg,
                        trailingIcon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account?  ",
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(
                              text: 'Register',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Get.toNamed(AppRoutes.register),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
