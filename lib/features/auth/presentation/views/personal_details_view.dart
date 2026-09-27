import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
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
      title: 'Your details',
      subtitle: 'Tell us who you are.',
      child: Form(
        key: controller.formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValidatedTextField(
                label: 'Full name',
                controller: controller.nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                inputFormatters: [CapitalizeFirstLetterFormatter()],
                hintText: 'e.g. Ramesh Kumar',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (v.trim().length < 2) {
                    return 'Enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              ValidatedTextField(
                label: 'Mobile number',
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
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
              const SizedBox(height: AppSpacing.xl),
              ValidatedTextField(
                label: 'Referral code',
                optional: true,
                controller: controller.referralController,
                textCapitalization: TextCapitalization.characters,
                // Only closes the keyboard: the terms row sits before Continue.
                textInputAction: TextInputAction.done,
                hintText: 'e.g. KX-0A1B-C2D3',
                prefixIcon: const Icon(Icons.card_giftcard_outlined),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Obx(
                () => _TermsCheckbox(
                  value: controller.agreedToTerms.value,
                  onChanged: (v) => controller.setAgreedToTerms(v ?? false),
                  showError: controller.showTermsError.value,
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
              const SizedBox(height: AppSpacing.xl),
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
                        // Return to the existing Login instead of stacking
                        // a second one.
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            final nav = Navigator.of(context);
                            if (nav.canPop()) {
                              nav.pop();
                            } else {
                              Get.offAllNamed(AppRoutes.login);
                            }
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
    );
  }
}

/// The terms agreement: the whole row toggles the checkbox, and an inline
/// error appears under it when the user tries to continue without agreeing.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.showError,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final strong = AppTextStyles.bodyMd.copyWith(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          // Gives the ripple a surface above the white card.
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => onChanged(!value),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Checkbox(
                      value: value,
                      onChanged: onChanged,
                      side: showError
                          ? const BorderSide(color: AppColors.error, width: 2)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          children: [
                            // Not link-styled until the documents can open.
                            TextSpan(text: 'Terms of Service', style: strong),
                            const TextSpan(text: ' and '),
                            TextSpan(text: 'Privacy Policy', style: strong),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: 52, top: AppSpacing.xs),
            child: Semantics(
              liveRegion: true,
              child: Text(
                'Please accept the Terms of Service and Privacy Policy to '
                'continue.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
            ),
          ),
      ],
    );
  }
}
