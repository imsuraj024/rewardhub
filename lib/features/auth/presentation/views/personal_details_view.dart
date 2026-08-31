import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/phone_input_formatter.dart';
import 'package:rewardhub/core/utils/text_input_formatters.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/auth/presentation/controllers/personal_details_controller.dart';
import 'package:rewardhub/features/auth/presentation/widgets/register_step_scaffold.dart';
import 'package:rewardhub/features/auth/presentation/widgets/validated_text_field.dart';

/// Registration step 1 — name, mobile number and referral code.
class PersonalDetailsView extends GetView<PersonalDetailsController> {
  const PersonalDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return RegisterStepScaffold(
      currentStep: 1,
      totalSteps: 3,
      title: 'Personal Details',
      subtitle: 'Tell us who you are to get started.',
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValidatedTextField(
              label: 'FULL NAME',
              controller: controller.nameController,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [CapitalizeFirstLetterFormatter()],
              hintText: 'John Doe',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Name is required';
                }
                if (v.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ValidatedTextField(
              label: 'MOBILE NUMBER',
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              hintText: '98765 43210',
              prefixIcon: const Icon(Icons.phone_android_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Mobile number is required';
                }
                final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                if (digits.length != 10) {
                  return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ValidatedTextField(
              label: 'REFERRAL CODE',
              optional: true,
              controller: controller.referralController,
              textCapitalization: TextCapitalization.characters,
              hintText: 'KITOX-2024',
              prefixIcon: const Icon(Icons.card_giftcard_outlined),
            ),
            const SizedBox(height: 24),
            Obx(
              () => _TermsCheckbox(
                value: controller.agreedToTerms.value,
                onChanged: (v) => controller.setAgreedToTerms(v ?? false),
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Continue',
              onPressed: controller.onNext,
              isFullWidth: true,
              size: AppButtonSize.lg,
              trailingIcon: const Icon(Icons.arrow_forward_rounded),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text.rich(
                TextSpan(
                  text: 'Already have an account?  ',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  children: [
                    TextSpan(
                      text: 'Log in',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Get.toNamed(AppRoutes.login),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: AppColors.outlineVariant),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'By registering, I agree to the ',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
