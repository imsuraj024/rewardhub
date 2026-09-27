import 'package:flutter/material.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';

/// Elevated white card that wraps the form on every auth screen.
///
/// Uses 16 dp padding on compact phones (< 360 dp wide), 24 dp otherwise.
class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 360 ? AppSpacing.lg : AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
