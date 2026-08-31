import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
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
    return PopScope(
      canPop: !widget.service.isDownloading,
      child: Dialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            final isDownloading = widget.service.isDownloading;
            final isRestartReady =
                _isRestartReady || widget.service.isRestartRequired;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderIcon(
                  isDownloading: isDownloading,
                  isRestartReady: isRestartReady,
                ),
                const SizedBox(height: 20),
                _buildTitle(
                  isDownloading: isDownloading,
                  isRestartReady: isRestartReady,
                ),
                const SizedBox(height: 10),
                _buildDescription(
                  isDownloading: isDownloading,
                  isRestartReady: isRestartReady,
                ),
                if (!isDownloading && !isRestartReady) ...[
                  const SizedBox(height: 16),
                  _buildPatchInfoBadge(),
                ],
                const SizedBox(height: 24),
                _buildActions(
                  isDownloading: isDownloading,
                  isRestartReady: isRestartReady,
                ),
              ],
            );
          }),
        ),
      ),
    );
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
      (_, true) => 'Update Installed!',
      (true, _) => 'Downloading Update...',
      _ => 'New Update Available',
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
      (_, true) =>
        'The latest patch has been downloaded. Restart the app now to apply new features and improvements.',
      (true, _) =>
        'Downloading the latest improvements in the background. This will only take a moment.',
      _ =>
        'A new update is available for Kitox Hardware with important bug fixes and performance improvements.',
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

  Widget _buildPatchInfoBadge() {
    final currentPatch = widget.service.currentPatchNumber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            currentPatch != null
                ? 'Current Version: Patch #$currentPatch'
                : 'Current Version: Base Release',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
          'Please do not close the app...',
          style: AppTextStyles.bodySm,
        ),
      );
    }

    if (isRestartReady) {
      return Column(
        children: [
          AppButton(
            label: 'Restart Now',
            isFullWidth: true,
            leadingIcon: const Icon(Icons.restart_alt_rounded, size: 18),
            onPressed: () {
              Get.back();
              widget.service.restartApp();
            },
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Restart Later',
            variant: AppButtonVariant.secondary,
            isFullWidth: true,
            onPressed: () => Get.back(),
          ),
        ],
      );
    }

    return Column(
      children: [
        AppButton(
          label: 'Update Now',
          isFullWidth: true,
          leadingIcon: const Icon(Icons.download_rounded, size: 18),
          onPressed: _startDownload,
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Later',
          variant: AppButtonVariant.secondary,
          isFullWidth: true,
          onPressed: () => Get.back(),
        ),
      ],
    );
  }
}
