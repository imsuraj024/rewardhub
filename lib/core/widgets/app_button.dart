import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Button variants per DESIGN.md
enum AppButtonVariant {
  /// Gradient fill — primary CTA
  primary,

  /// Ghost — no fill, ghost border, primary text
  secondary,

  /// White fill with primary text — for use on dark/primary backgrounds
  inverted,

  /// Transparent fill, visible outline_variant border, primary text
  outline,
}

/// Sizing
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  // ── Size tokens ──────────────────────────────────────────────────────────────
  EdgeInsets get _padding => switch (size) {
    AppButtonSize.sm => const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 10,
    ),
    AppButtonSize.md => const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 14,
    ),
    AppButtonSize.lg => const EdgeInsets.symmetric(
      horizontal: 32,
      vertical: 18,
    ),
  };

  double get _fontSize => switch (size) {
    AppButtonSize.sm => 11,
    AppButtonSize.md => 12,
    AppButtonSize.lg => 14,
  };

  double get _iconSize => switch (size) {
    AppButtonSize.sm => 14,
    AppButtonSize.md => 16,
    AppButtonSize.lg => 18,
  };

  // ── Variant resolvers ────────────────────────────────────────────────────────
  Color get _textColor => switch (variant) {
    AppButtonVariant.primary => AppColors.onPrimary,
    AppButtonVariant.secondary => AppColors.primary,
    AppButtonVariant.inverted => AppColors.primary,
    AppButtonVariant.outline => AppColors.primary,
  };

  BoxDecoration _buildDecoration(bool pressed) {
    final opacity = onPressed == null ? 0.4 : (pressed ? 0.85 : 1.0);

    return switch (variant) {
      AppButtonVariant.primary => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: opacity),
            AppColors.primaryContainer.withValues(alpha: opacity),
          ],
          transform: const GradientRotation(135 * 3.14159265 / 180),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: pressed
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      AppButtonVariant.secondary => BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // outline_variant at 20% opacity
          color: AppColors.outlineVariant.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      AppButtonVariant.inverted => BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(12),
        boxShadow: pressed
            ? null
            : [
                const BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
      ),
      AppButtonVariant.outline => BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.labelMd.copyWith(
      fontSize: _fontSize,
      color: _textColor,
      letterSpacing: 0.5,
    );

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_textColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (leadingIcon != null) ...[
          IconTheme(
            data: IconThemeData(size: _iconSize, color: _textColor),
            child: leadingIcon!,
          ),
          const SizedBox(width: 8),
        ],
        Text(label, style: labelStyle),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 8),
          IconTheme(
            data: IconThemeData(size: _iconSize, color: _textColor),
            child: trailingIcon!,
          ),
        ],
      ],
    );

    if (isFullWidth) {
      buttonChild = Center(child: buttonChild);
    }

    return _PressableContainer(
      padding: _padding,
      isFullWidth: isFullWidth,
      onTap: (onPressed != null && !isLoading) ? onPressed : null,
      buildDecoration: _buildDecoration,
      child: buttonChild,
    );
  }
}

/// Handles press animation and decoration swap
class _PressableContainer extends StatefulWidget {
  const _PressableContainer({
    required this.padding,
    required this.isFullWidth,
    required this.buildDecoration,
    required this.child,
    this.onTap,
  });

  final EdgeInsets padding;
  final bool isFullWidth;
  final BoxDecoration Function(bool pressed) buildDecoration;
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableContainer> createState() => _PressableContainerState();
}

class _PressableContainerState extends State<_PressableContainer> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.isFullWidth ? double.infinity : null,
          padding: widget.padding,
          decoration: widget.buildDecoration(_pressed),
          child: widget.child,
        ),
      ),
    );
  }
}
