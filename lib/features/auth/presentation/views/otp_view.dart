import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/l10n_extension.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/otp_controller.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_header.dart';
import 'package:rewardhub/features/auth/presentation/widgets/otp_box.dart';

class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

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
                      AuthHeader(
                        title: AppStrings.productName,
                        subtitle: context.l10n.curatorSubtitle,
                      ),
                      const SizedBox(height: 32),
                      AuthFormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.verifyAccess,
                              style: AppTextStyles.headlineSm,
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                text: context.l10n.codeSentTo,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${controller.maskedPhone}.',
                                    style: AppTextStyles.bodyMd.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            AutofillGroup(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  OtpController.otpLength,
                                  (i) => OtpBox(
                                    controller: controller.controllers[i],
                                    focusNode: controller.focusNodes[i],
                                    onChanged: (v) =>
                                        controller.onDigitChanged(i, v),
                                    autofocus: i == 0,
                                  ),
                                ),
                              ),
                            ),
                            Obx(() {
                              final err = auth.errorMessage;
                              if (err == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  err,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 32),
                            Obx(
                              () => AppButton(
                                label: context.l10n.verifyIdentity,
                                onPressed: auth.isLoading
                                    ? null
                                    : controller.onVerify,
                                isLoading: auth.isLoading,
                                isFullWidth: true,
                                size: AppButtonSize.lg,
                                trailingIcon: const Icon(
                                  Icons.arrow_forward_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Obx(
                                () => Text.rich(
                                  TextSpan(
                                    text: context.l10n.didNotGetCode,
                                    style: AppTextStyles.bodyMd.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    children: [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: GestureDetector(
                                          onTap: controller.canResend.value
                                              ? controller.onResend
                                              : null,
                                          child: Text(
                                            context.l10n.resendCode,
                                            style: AppTextStyles.bodyMd
                                                .copyWith(
                                                  color:
                                                      controller.canResend.value
                                                      ? AppColors.primary
                                                      : AppColors
                                                            .onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Obx(() {
                        if (controller.canResend.value) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowColor,
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.codeValidFor(
                                  controller.timerLabel,
                                ),
                                style: AppTextStyles.labelSm.copyWith(
                                  letterSpacing: 1.1,
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
