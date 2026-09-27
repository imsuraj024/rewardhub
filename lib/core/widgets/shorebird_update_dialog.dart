import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/constants/app_strings.dart';
import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/widgets/app_button.dart';

/// Interactive modal dialog that presents Shorebird OTA updates to the user.
///
/// Handles three states:
/// 1. Update Available: Prompting the user to download the latest patch.
/// 2. Downloading: Showing an in-progress indicator while the patch is fetched.
/// 3. Restart Required: Prompting the user to restart the app to apply the update.
class ShorebirdUpdateDialog extends StatefulWidget {
  const ShorebirdUpdateDialog({
    super.key,
    required this.service,
    this.initialRestartReady = false,
  });

  final ShorebirdUpdateService service;
  final bool initialRestartReady;

  @override
  State<ShorebirdUpdateDialog> createState() => _ShorebirdUpdateDialogState();
}

class _ShorebirdUpdateDialogState extends State<ShorebirdUpdateDialog> {
  late bool _isRestartReady;

  @override
  void initState() {
    super.initState();
    _isRestartReady = widget.initialRestartReady;
  }

  Future<void> _startDownload() async {
    final success = await widget.service.downloadAndApplyUpdate();
    if (mounted && success) {
      setState(() {
        _isRestartReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // The Obx encloses PopScope so back stays blocked for exactly as long as
    // the download runs.
    return Obx(() {
      final isDownloading = widget.service.isDownloading;
      final isRestartReady =
          _isRestartReady || widget.service.isRestartRequired;

      return PopScope(
        canPop: !isDownloading,
        child: Dialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xxl,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderIcon(
                  isDownloading: isDownloading,
                  isRestartReady: isRestartReady,
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildTitle(
                  isDownloading: isDownloading,
                  isRestartReady: isRestartReady,
                ),
                const SizedBox(height: 10),
                _buildDescription(
                  isDownloading: isDownloading,
                  isRestartReady: isRestartReady,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildActions(
                  isDownloading: isDownloading,
                  isRestartReady: isRestartReady,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeaderIcon({
    required bool isDownloading,
    required bool isRestartReady,
  }) {
    if (isRestartReady) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.successContainer,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 36,
        ),
      );
    }

    if (isDownloading) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primaryFixed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.system_update_rounded,
        color: AppColors.onPrimary,
        size: 32,
      ),
    );
  }

  Widget _buildTitle({
    required bool isDownloading,
    required bool isRestartReady,
  }) {
    final title = switch ((isDownloading, isRestartReady)) {
      (_, true) => 'Update ready',
      (true, _) => 'Downloading update…',
      _ => 'Update available',
    };

    return Text(
      title,
      style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w700),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription({
    required bool isDownloading,
    required bool isRestartReady,
  }) {
    final text = switch ((isDownloading, isRestartReady)) {
      (_, true) => 'Restart the app to finish updating.',
      (true, _) => 'Downloading the latest improvements.',
      _ =>
        'A new update is available for ${AppStrings.productName} with important bug fixes and performance improvements.',
    };

    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyMd.copyWith(
        color: AppColors.onSurfaceVariant,
        height: 1.45,
      ),
    );
  }

  Widget _buildActions({
    required bool isDownloading,
    required bool isRestartReady,
  }) {
    if (isDownloading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Keep the app open until this finishes.',
          style: AppTextStyles.bodySm,
        ),
      );
    }

    if (isRestartReady) {
      return Column(
        children: [
          AppButton(
            label: 'Restart now',
            isFullWidth: true,
            leadingIcon: const Icon(Icons.restart_alt_rounded, size: 18),
            onPressed: () {
              Get.back();
              widget.service.restartApp();
            },
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Restart later',
            variant: AppButtonVariant.outline,
            isFullWidth: true,
            onPressed: () => Get.back(),
          ),
        ],
      );
    }

    return Column(
      children: [
        AppButton(
          label: 'Update now',
          isFullWidth: true,
          leadingIcon: const Icon(Icons.download_rounded, size: 18),
          onPressed: _startDownload,
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Later',
          variant: AppButtonVariant.outline,
          isFullWidth: true,
          onPressed: () => Get.back(),
        ),
      ],
    );
  }
}
