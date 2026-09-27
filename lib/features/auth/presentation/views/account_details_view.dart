import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/payment_validators.dart';
import 'package:rewardhub/core/utils/text_input_formatters.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/auth/presentation/controllers/account_details_controller.dart';
import 'package:rewardhub/features/auth/presentation/widgets/register_step_scaffold.dart';
import 'package:rewardhub/features/auth/presentation/widgets/validated_text_field.dart';

/// Registration step 2 — payout details (UPI / Google Pay or bank account).
class AccountDetailsView extends GetView<AccountDetailsController> {
  const AccountDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return RegisterStepScaffold(
      currentStep: 2,
      totalSteps: 3,
      title: 'Payment details',
      subtitle: 'Where should we send your money?',
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => ValidatedTextField(
                label: 'UPI ID or Google Pay number',
                controller: controller.upiController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: controller.showBankDetails.value
                    ? TextInputAction.next
                    : TextInputAction.done,
                hintText: 'name@okhdfcbank or 10-digit number',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                validator: (v) =>
                    PaymentValidators.upiOrGooglePay(v, required: true),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _OrDivider(),
            const SizedBox(height: AppSpacing.xl),
            Obx(() {
              if (!controller.showBankDetails.value) {
                return AppButton(
                  label: 'Add bank account',
                  onPressed: controller.revealBankDetails,
                  variant: AppButtonVariant.outline,
                  isFullWidth: true,
                  size: AppButtonSize.lg,
                  leadingIcon: const Icon(Icons.account_balance_outlined),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValidatedTextField(
                    label: 'Account number',
                    optional: true,
                    controller: controller.accountNumberController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(18),
                    ],
                    hintText: '1234567890',
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                    validator: PaymentValidators.accountNumber,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ValidatedTextField(
                    label: 'IFSC code',
                    optional: true,
                    controller: controller.ifscController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => controller.onNext(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(11),
                    ],
                    hintText: 'SBIN0001234',
                    prefixIcon: const Icon(Icons.qr_code_2_outlined),
                    validator: PaymentValidators.ifscCode,
                  ),
                ],
              );
            }),
            const SizedBox(height: 28),
            AppButton(
              label: 'Continue',
              onPressed: controller.onNext,
              isFullWidth: true,
              size: AppButtonSize.lg,
              trailingIcon: const Icon(Icons.arrow_forward_rounded),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Back',
              onPressed: Get.back,
              variant: AppButtonVariant.outline,
              isFullWidth: true,
              size: AppButtonSize.lg,
              leadingIcon: const Icon(Icons.arrow_back_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section label for the optional bank fields, between two decorative lines.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(
        color: AppColors.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // The label takes its natural width, wrapping only when it would
        // leave less than AppSpacing.xxl of line on each side.
        final maxLabelWidth =
            (constraints.maxWidth - 2 * (AppSpacing.md + AppSpacing.xxl))
                .clamp(0.0, double.infinity);
        return Row(
          children: [
            line,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxLabelWidth),
                child: Text(
                  'Bank account (optional)',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.overline,
                ),
              ),
            ),
            line,
          ],
        );
      },
    );
  }
}
