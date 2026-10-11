import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/widgets/app_bottom_sheet.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/auth/presentation/controllers/kyc_controller.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_field_label.dart';
import 'package:rewardhub/features/auth/presentation/widgets/dashed_border.dart';
import 'package:rewardhub/features/auth/presentation/widgets/register_step_scaffold.dart';

/// Registration step 3 — KYC document upload (Aadhaar photo + selfie).
///
/// Back (system and button) is blocked while the registration is uploading.
class KycView extends GetView<KycController> {
  const KycView({super.key});

  @override
  Widget build(BuildContext context) {
    // The Obx encloses canPop so back unblocks as soon as the upload ends.
    return Obx(
      () => RegisterStepScaffold(
        currentStep: 3,
        totalSteps: 3,
        title: 'Verify your identity',
        subtitle:
            'Upload your Aadhaar card and a selfie to verify your identity.',
        canPop: !controller.isLoading,
        onPopBlocked: () =>
            AppToast.info("Please wait. We're sending your details."),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthFieldLabel('Aadhaar card photo'),
            const SizedBox(height: AppSpacing.sm),
            Obx(
              () => _UploadTile(
                icon: Icons.badge_outlined,
                label: 'Add Aadhaar photo',
                hint: 'Front side. All 4 corners visible.',
                path: controller.aadhaarPath.value,
                onTap: () => _showAadhaarSourceSheet(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AuthFieldLabel('Selfie'),
            const SizedBox(height: AppSpacing.sm),
            Obx(
              () => _UploadTile(
                icon: Icons.face_retouching_natural_outlined,
                label: 'Take a selfie',
                hint: 'Face clearly visible, good lighting',
                path: controller.selfiePath.value,
                onTap: () => _takePhoto(context, KycDocument.selfie),
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Submit for review',
              onPressed: controller.isLoading ? null : controller.onSubmit,
              isLoading: controller.isLoading,
              isFullWidth: true,
              size: AppButtonSize.lg,
              trailingIcon: const Icon(Icons.check_rounded),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Back',
              onPressed: controller.isLoading ? null : Get.back,
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

  void _showAadhaarSourceSheet(BuildContext context) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        title: 'Add Aadhaar photo',
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _takePhoto(context, KycDocument.aadhaar);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                controller.pickAadhaar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Camera capture for one document: the rationale or "Camera is off"
  /// sheet when needed, then the picker (DS-26). Uses the view's context,
  /// never a closed sheet's context.
  Future<void> _takePhoto(BuildContext context, KycDocument document) async {
    final access = await controller.cameraAccess();
    if (!context.mounted) return;
    if (access == KycCameraAccess.blocked) {
      await _showCameraOff(context, document);
      return;
    }
    if (access == KycCameraAccess.explain) {
      final go = await AppBottomSheet.confirm(
        context: context,
        icon: Icons.photo_camera_rounded,
        title: 'Allow camera to take a photo',
        message: document == KycDocument.aadhaar
            ? 'We need your camera to take a photo of your Aadhaar card. '
                'Your phone may ask you to allow this.'
            : 'We need your camera to take your selfie. '
                'Your phone may ask you to allow this.',
        confirmLabel: 'Continue',
        cancelLabel: 'Not now',
      );
      if (!go || !context.mounted) return;
      controller.cameraExplained();
    }
    final result = document == KycDocument.aadhaar
        ? await controller.pickAadhaar(ImageSource.camera)
        : await controller.pickSelfie();
    if (result == KycPickResult.cameraBlocked && context.mounted) {
      await _showCameraOff(context, document);
    }
  }

  Future<void> _showCameraOff(
    BuildContext context,
    KycDocument document,
  ) async {
    final open = await AppBottomSheet.confirm(
      context: context,
      icon: Icons.no_photography_rounded,
      title: 'Camera is off',
      message: document == KycDocument.aadhaar
          ? 'Tap Open settings, then turn on Camera. '
              'You can also choose a photo from your gallery.'
          : 'Tap Open settings, then turn on Camera.',
      confirmLabel: 'Open settings',
      cancelLabel: 'Not now',
    );
    if (open) await controller.openSettings();
  }
}

/// Dashed-style upload slot that shows a preview once an image is picked.
///
/// Grows past its 120 dp minimum when the text needs more room.
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
    return Semantics(
      button: true,
      label: hasImage ? '$label. Added. Tap to change.' : '$label. $hint',
      excludeSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              height: hasImage ? 120 : null,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: hasImage
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: hasImage ? _preview() : _emptySlot(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptySlot() {
    return CustomPaint(
      painter: DashedRRectPainter(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      cacheWidth: 800,
      excludeFromSemantics: true,
      // The footer only appears once the photo has actually decoded, so a
      // missing file never claims "Added".
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        final loaded = frame != null || wasSynchronouslyLoaded;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (loaded)
              Positioned(left: 0, right: 0, bottom: 0, child: _footer()),
          ],
        );
      },
      errorBuilder: (_, __, ___) => ColoredBox(
        color: AppColors.surfaceContainerLow,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  size: 28,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 6),
                Text(
                  'Photo not found. Tap to add it again.',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Scrim footer confirming the photo was added (white on scrim ≥ 6.74:1).
  Widget _footer() {
    return Container(
      color: AppColors.scrim,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.onPrimary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Added',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Tap to change',
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
