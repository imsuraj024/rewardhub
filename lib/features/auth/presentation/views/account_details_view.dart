import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
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
      title: 'Account Details',
      subtitle: 'Where should we send your rewards?',
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValidatedTextField(
              label: 'UPI ID / GOOGLE PAY NUMBER',
              controller: controller.upiController,
              keyboardType: TextInputType.emailAddress,
              hintText: 'name@upi or 98765 43210',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              validator: (v) =>
                  PaymentValidators.upiOrGooglePay(v, required: true),
            ),
            const SizedBox(height: 20),
            _OrDivider(),
            const SizedBox(height: 20),
            Obx(() {
              if (!controller.showBankDetails.value) {
                return AppButton(
                  label: 'Add Bank Account Details',
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
                    label: 'ACCOUNT NUMBER',
                    optional: true,
                    controller: controller.accountNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    hintText: '1234567890',
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                    validator: PaymentValidators.accountNumber,
                  ),
                  const SizedBox(height: 20),
                  ValidatedTextField(
                    label: 'IFSC CODE',
                    optional: true,
                    controller: controller.ifscController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      UpperCaseTextFormatter(),
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
            const SizedBox(height: 12),
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

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(
        color: AppColors.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR ADD BANK DETAILS',
            style: AppTextStyles.labelSm.copyWith(
              letterSpacing: 1.1,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        line,
      ],
    );
  }
}
