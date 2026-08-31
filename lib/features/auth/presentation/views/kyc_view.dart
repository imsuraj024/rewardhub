import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/auth/presentation/controllers/kyc_controller.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_field_label.dart';
import 'package:rewardhub/features/auth/presentation/widgets/dashed_border.dart';
import 'package:rewardhub/features/auth/presentation/widgets/register_step_scaffold.dart';

/// Registration step 3 — KYC document upload (Aadhaar photo + selfie).
class KycView extends GetView<KycController> {
  const KycView({super.key});

  @override
  Widget build(BuildContext context) {
    return RegisterStepScaffold(
      currentStep: 3,
      totalSteps: 3,
      title: 'Identity Verification',
      subtitle:
          'Upload your Aadhaar card and a selfie to verify your identity.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthFieldLabel('AADHAAR CARD PHOTO'),
          const SizedBox(height: 8),
          Obx(
            () => _UploadTile(
              icon: Icons.badge_outlined,
              label: 'Upload Aadhaar card',
              hint: 'Front side, clearly visible',
              path: controller.aadhaarPath.value,
              onTap: () => _showAadhaarSourceSheet(context),
            ),
          ),
          const SizedBox(height: 20),
          const AuthFieldLabel('SELFIE'),
          const SizedBox(height: 8),
          Obx(
            () => _UploadTile(
              icon: Icons.face_retouching_natural_outlined,
              label: 'Take a selfie',
              hint: 'Face clearly visible, good lighting',
              path: controller.selfiePath.value,
              onTap: controller.pickSelfie,
            ),
          ),
          const SizedBox(height: 28),
          Obx(
            () => AppButton(
              label: 'Submit & Verify',
              onPressed: controller.isLoading ? null : controller.onSubmit,
              isLoading: controller.isLoading,
              isFullWidth: true,
              size: AppButtonSize.lg,
              trailingIcon: const Icon(Icons.check_rounded),
            ),
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
    );
  }

  void _showAadhaarSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Get.back();
                controller.pickAadhaar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Get.back();
                controller.pickAadhaar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Dashed-style upload slot that shows a preview once an image is picked.
class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.path,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = path.isNotEmpty;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: hasImage
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(path), fit: BoxFit.cover),
                    // Darkened footer with an "Uploaded" confirmation.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: AppColors.onSurface.withValues(alpha: 0.55),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Uploaded',
                              style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Tap to change',
                              style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : CustomPaint(
                  painter: DashedRRectPainter(color: AppColors.outlineVariant),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 28, color: AppColors.primary),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hint,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
