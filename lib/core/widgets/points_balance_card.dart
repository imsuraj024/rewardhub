import 'package:flutter/material.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';
import 'package:rewardhub/core/utils/app_format.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';

/// The points hero card shared by Home and Wallet.
///
/// Shows one of three states, never an invented number:
/// - value: [points] is set (also while a refresh runs with a stale value);
/// - loading: [points] is null and [isLoading] is true — a skeleton;
/// - error: [points] is null and nothing is loading — "—", [errorMessage] and,
///   with [onRetry], a "Try again" button.
///
/// The optional [graphic] hides itself when the card is narrower than 280 dp
/// inside its padding, so it never overlaps the number.
class PointsBalanceCard extends StatelessWidget {
  const PointsBalanceCard({
    super.key,
    required this.label,
    required this.points,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.badge,
    this.graphic,
    this.footer,
  });

  /// 'Your points' (Home) / 'Available points' (Wallet).
  final String label;

  /// null = no value from the server yet.
  final int? points;

  /// A load is in flight.
  final bool isLoading;

  /// Shown only in the error state.
  final String? errorMessage;

  /// Shows "Try again" in the error state.
  final VoidCallback? onRetry;

  /// Small chip on the label row (e.g. weekly trend).
  final Widget? badge;

  /// Decorative right-hand graphic (e.g. coins).
  final Widget? graphic;

  /// Full-width content under the value (e.g. weekly chart).
  final Widget? footer;

  Widget _labelRow() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLg.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (badge != null) badge!,
      ],
    );
  }

  Widget _valueArea() {
    final value = points;
    if (value != null) {
      return Semantics(
        label: '$label, ${AppFormat.pointsWithUnit(value)}',
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(AppFormat.points(value), style: AppTextStyles.pointsHero),
              const SizedBox(width: AppSpacing.sm),
              Text(
                value == 1 ? 'point' : 'points',
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return Semantics(
        label: '$label, loading',
        child: const Shimmer(
          onDark: true,
          child: SkeletonBox(
            width: 140,
            height: 40,
            radius: AppRadius.sm,
            onDark: true,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '$label, not available',
          excludeSemantics: true,
          child: Text('—', style: AppTextStyles.pointsHero),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          errorMessage ?? "Couldn't load your points.",
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onPrimary),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Try again',
            onPressed: onRetry,
            variant: AppButtonVariant.inverted,
            size: AppButtonSize.sm,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final showGraphic =
                  graphic != null && constraints.maxWidth >= 280;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _labelRow(),
                        const SizedBox(height: AppSpacing.sm),
                        _valueArea(),
                      ],
                    ),
                  ),
                  if (showGraphic) ...[
                    const SizedBox(width: AppSpacing.md),
                    ExcludeSemantics(
                      child: SizedBox(width: 88, height: 80, child: graphic),
                    ),
                  ],
                ],
              );
            },
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.lg),
            footer!,
          ],
        ],
      ),
    );
  }
}
