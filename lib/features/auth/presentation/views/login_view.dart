import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
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
          gradient: AppColors.authBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.authGutter,
                    vertical: AppSpacing.xxxl,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      const AuthHeader(
                        title: AppStrings.productName,
                        subtitle: 'Scan, earn, and redeem rewards every day.',
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      AuthFormCard(
                        child: Form(
                          key: controller.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome',
                                style: AppTextStyles.headlineSm,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Enter your mobile number to continue.',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 28),
                              ValidatedTextField(
                                label: 'Mobile number',
                                controller: controller.phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                onFieldSubmitted: (_) {
                                  if (!auth.isLoading) controller.onContinue();
                                },
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.authGutter,
                  AppSpacing.sm,
                  AppSpacing.authGutter,
                  AppSpacing.lg,
                ),
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
                    const SizedBox(height: AppSpacing.lg),
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
