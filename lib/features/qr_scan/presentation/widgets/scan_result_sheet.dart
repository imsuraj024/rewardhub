import 'package:flutter/material.dart';

import 'package:rewardhub/core/widgets/app_bottom_sheet.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';

/// The outcome of a scan: "Points added" or "Couldn't add points", with the
/// message and one button that closes the sheet so the next scan can start.
class ScanResultSheet extends StatelessWidget {
  const ScanResultSheet({
    super.key,
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  /// Completes when the sheet closes: button, back, scrim tap or drag.
  static Future<void> show(
    BuildContext context, {
    required bool success,
    required String message,
  }) =>
      AppBottomSheet.show<void>(
        context: context,
        builder: (_) => ScanResultSheet(success: success, message: message),
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: AppBottomSheet(
        centerHeader: true,
        icon: AppIconBadge(
          icon: success
              ? Icons.check_circle_rounded
              : Icons.error_outline_rounded,
          tone: success ? AppIconBadgeTone.success : AppIconBadgeTone.error,
          size: AppIconBadgeSize.lg,
        ),
        title: success ? 'Points added' : "Couldn't add points",
        message: message,
        actions: [
          AppButton(
            label: success ? 'Scan another code' : 'Scan again',
            size: AppButtonSize.lg,
            isFullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
