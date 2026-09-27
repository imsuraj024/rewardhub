import 'package:flutter/material.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';

/// Box size of an [AppIconBadge]: sm 32, md 40, lg 56.
enum AppIconBadgeSize { sm, md, lg }

/// Fill / icon colour pair of an [AppIconBadge].
enum AppIconBadgeTone { primary, success, error, warning, gold, neutral }

/// A tinted square (or circle) holding one icon — the leading visual of list
/// rows, sheets, empty states and status cards.
///
/// Decorative by default (no semantics). Pass [semanticLabel] when the icon
/// carries meaning that isn't written next to it. Use `*_rounded` glyphs.
///
/// ```dart
/// const AppIconBadge(icon: Icons.wallet_rounded, tone: AppIconBadgeTone.gold)
/// ```
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.tone = AppIconBadgeTone.primary,
    this.size = AppIconBadgeSize.md,
    this.circular = false,
    this.isLoading = false,
    this.semanticLabel,
  });

  final IconData icon;
  final AppIconBadgeTone tone;
  final AppIconBadgeSize size;

  /// Circle instead of a rounded square.
  final bool circular;

  /// Replaces the icon with a spinner in the icon colour.
  final bool isLoading;
  final String? semanticLabel;

  double get _box => switch (size) {
        AppIconBadgeSize.sm => 32,
        AppIconBadgeSize.md => 40,
        AppIconBadgeSize.lg => 56,
      };

  double get _iconSize => switch (size) {
        AppIconBadgeSize.sm => 16,
        AppIconBadgeSize.md => 20,
        AppIconBadgeSize.lg => 28,
      };

  double get _radius => switch (size) {
        AppIconBadgeSize.sm => AppRadius.sm,
        AppIconBadgeSize.md => AppRadius.md,
        AppIconBadgeSize.lg => AppRadius.lg,
      };

  Color get _fill => switch (tone) {
        AppIconBadgeTone.primary => AppColors.primaryFixed,
        AppIconBadgeTone.success => AppColors.successContainer,
        AppIconBadgeTone.error => AppColors.errorContainer,
        AppIconBadgeTone.warning => AppColors.warningContainer,
        AppIconBadgeTone.gold => AppColors.tertiaryFixed,
        AppIconBadgeTone.neutral => AppColors.surfaceContainerHigh,
      };

  Color get _iconColor => switch (tone) {
        AppIconBadgeTone.primary => AppColors.primary,
        AppIconBadgeTone.success => AppColors.success,
        AppIconBadgeTone.error => AppColors.error,
        AppIconBadgeTone.warning => AppColors.warning,
        AppIconBadgeTone.gold => AppColors.tertiaryStrong,
        AppIconBadgeTone.neutral => AppColors.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final spinnerSize = _iconSize - 2;
    final badge = Container(
      width: _box,
      height: _box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _fill,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(_radius),
      ),
      child: isLoading
          ? SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _iconColor,
              ),
            )
          : Icon(icon, size: _iconSize, color: _iconColor),
    );

    if (semanticLabel == null) return ExcludeSemantics(child: badge);
    return Semantics(label: semanticLabel, image: true, child: badge);
  }
}
