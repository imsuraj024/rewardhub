import 'package:flutter/material.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';

/// One empty/error state for every section: icon badge, title, optional
/// message and optional action.
///
/// - Error states use `tone: AppIconBadgeTone.error` and an action labelled
///   "Try again". They are announced as a live region.
/// - Empty states say why the section is empty and what to do next.
///
/// ```dart
/// AppStateMessage(
///   icon: Icons.error_outline_rounded,
///   tone: AppIconBadgeTone.error,
///   title: "Couldn't load your transactions",
///   actionLabel: 'Try again',
///   onAction: controller.reload,
/// )
/// ```
class AppStateMessage extends StatelessWidget {
  const AppStateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tone = AppIconBadgeTone.primary,
    this.boxed = true,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// The button shows only when both [actionLabel] and [onAction] are set.
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppIconBadgeTone tone;

  /// true → a white rounded card; false → padding only.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppIconBadge(icon: icon, tone: tone, size: AppIconBadgeSize.lg),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTextStyles.titleMd, textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            message!,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: actionLabel!,
            onPressed: onAction,
            variant: AppButtonVariant.tonal,
          ),
        ],
      ],
    );

    return Semantics(
      container: true,
      liveRegion: tone == AppIconBadgeTone.error,
      child: boxed
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: content,
            )
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: content,
            ),
    );
  }
}
