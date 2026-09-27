import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
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
                      AuthHeader(
                        title: AppStrings.productName,
                        subtitle: context.l10n.curatorSubtitle,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      AuthFormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.verifyAccess,
                              style: AppTextStyles.headlineSm,
                            ),
                            const SizedBox(height: AppSpacing.sm),
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
                            const SizedBox(height: AppSpacing.xxxl),
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 376,
                                ),
                                child: AutofillGroup(
                                  child: Row(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < OtpController.otpLength;
                                        i++
                                      ) ...[
                                        Expanded(
                                          child: OtpBox(
                                            controller:
                                                controller.controllers[i],
                                            focusNode: controller.focusNodes[i],
                                            onChanged: (v) =>
                                                controller.onDigitChanged(i, v),
                                            autofocus: i == 0,
                                            semanticLabel:
                                                'Digit ${i + 1} of '
                                                '${OtpController.otpLength}',
                                          ),
                                        ),
                                        if (i < OtpController.otpLength - 1)
                                          const SizedBox(width: AppSpacing.sm),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Obx(() {
                              final err = auth.errorMessage;
                              if (err == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: Text(
                                  err,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: AppSpacing.xxxl),
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
                            const SizedBox(height: AppSpacing.xl),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    context.l10n.didNotGetCode.trimRight(),
                                    style: AppTextStyles.bodyMd.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Obx(
                                    () => TextButton(
                                      onPressed: controller.canResend.value
                                          ? controller.onResend
                                          : null,
                                      // The theme's foreground is primary in
                                      // every state; grey it while waiting.
                                      style: TextButton.styleFrom(
                                        disabledForegroundColor:
                                            AppColors.onSurfaceVariant,
                                      ),
                                      child: Text(context.l10n.resendCode),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Obx(() {
                        if (controller.canResend.value) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
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
                              const SizedBox(width: AppSpacing.sm),
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
