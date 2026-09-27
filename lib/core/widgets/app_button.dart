import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Button variants per DESIGN.md
enum AppButtonVariant {
  /// primaryGradient fill, onPrimary label (9.34 → 6.44:1). Main CTA.
  primary,

  /// primaryFixed fill, primary label (7.23:1). Secondary action that must
  /// look like a button.
  tonal,

  /// Transparent, 1 px `outline` border (4.49:1 on white, 4.26 on surface),
  /// primary label. Cancel / Back / Later.
  outline,

  /// Alias of [outline]: renders identically. Kept so existing call sites
  /// compile.
  secondary,

  /// surfaceContainerLowest fill, primary label (9.34:1). Use on primary or
  /// dark backgrounds.
  inverted,

  /// error fill, onError label (6.46:1). Irreversible actions (Delete
  /// account, Log out).
  destructive,
}

/// Sizing
enum AppButtonSize { sm, md, lg }

/// The app's button.
///
/// - `isLoading` wins over `onPressed == null`: a loading button keeps its
///   colours and shows a spinner; a disabled one turns grey.
/// - Full-width buttons wrap their label onto up to 2 lines.
/// - Non-full-width buttons: labels ≤ 16 characters. They keep one line so
///   they can sit in an unbounded `Row`.
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
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  /// Overrides [label] for screen readers.
  final String? semanticLabel;

  bool get _isInteractive => onPressed != null && !isLoading;

  bool get _isDisabled => onPressed == null && !isLoading;

  bool get _isOutlined =>
      variant == AppButtonVariant.outline ||
      variant == AppButtonVariant.secondary;

  // ── Size tokens ──────────────────────────────────────────────────────────────
  EdgeInsets get _padding => switch (size) {
        AppButtonSize.sm => const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 10,
          ),
        AppButtonSize.md => const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: 14,
          ),
        AppButtonSize.lg => const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl,
            vertical: 18,
          ),
      };

  double get _minHeight => switch (size) {
        AppButtonSize.sm => 40,
        AppButtonSize.md => 48,
        AppButtonSize.lg => 56,
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
  Color get _foregroundColor {
    if (_isDisabled) return AppColors.onSurfaceVariant;
    return switch (variant) {
      AppButtonVariant.primary => AppColors.onPrimary,
      AppButtonVariant.tonal => AppColors.primary,
      AppButtonVariant.outline => AppColors.primary,
      AppButtonVariant.secondary => AppColors.primary,
      AppButtonVariant.inverted => AppColors.primary,
      AppButtonVariant.destructive => AppColors.onError,
    };
  }

  Color get _focusRingColor => switch (variant) {
        AppButtonVariant.primary ||
        AppButtonVariant.destructive =>
          AppColors.onPrimary,
        _ => AppColors.onSurface,
      };

  BoxDecoration _buildDecoration(bool pressed) {
    final radius = BorderRadius.circular(AppRadius.md);

    if (_isDisabled) {
      return _isOutlined
          ? BoxDecoration(
              color: Colors.transparent,
              borderRadius: radius,
              border: Border.all(color: AppColors.outlineVariant, width: 1),
            )
          : BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: radius,
            );
    }

    return switch (variant) {
      AppButtonVariant.primary => BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: radius,
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
      AppButtonVariant.tonal => BoxDecoration(
          color: AppColors.primaryFixed,
          borderRadius: radius,
        ),
      AppButtonVariant.outline || AppButtonVariant.secondary => BoxDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: Border.all(color: AppColors.outline, width: 1),
        ),
      AppButtonVariant.inverted => BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: radius,
          boxShadow: pressed
              ? null
              : const [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 32,
                    offset: Offset(0, 12),
                  ),
                ],
        ),
      AppButtonVariant.destructive => BoxDecoration(
          color: AppColors.error,
          borderRadius: radius,
          boxShadow: pressed
              ? null
              : [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.24),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundColor;
    final labelStyle = AppTextStyles.labelMd.copyWith(
      fontSize: _fontSize,
      color: foreground,
      letterSpacing: 0.5,
    );

    final text = Text(
      label,
      style: labelStyle,
      maxLines: isFullWidth ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(foreground),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (leadingIcon != null) ...[
          IconTheme(
            data: IconThemeData(size: _iconSize, color: foreground),
            child: leadingIcon!,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (isFullWidth) Flexible(child: text) else text,
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: AppSpacing.sm),
          IconTheme(
            data: IconThemeData(size: _iconSize, color: foreground),
            child: trailingIcon!,
          ),
        ],
      ],
    );

    final spokenLabel = semanticLabel ?? label;

    return Semantics(
      container: true,
      button: true,
      enabled: _isInteractive,
      label: isLoading ? '$spokenLabel, loading' : spokenLabel,
      excludeSemantics: true,
      onTap: _isInteractive ? onPressed : null,
      child: _PressableContainer(
        padding: _padding,
        minHeight: _minHeight,
        isFullWidth: isFullWidth,
        focusRingColor: _focusRingColor,
        onTap: _isInteractive ? onPressed : null,
        buildDecoration: _buildDecoration,
        child: content,
      ),
    );
  }
}

/// Handles focus, keyboard activation, press animation and decoration swap.
class _PressableContainer extends StatefulWidget {
  const _PressableContainer({
    required this.padding,
    required this.minHeight,
    required this.isFullWidth,
    required this.focusRingColor,
    required this.buildDecoration,
    required this.child,
    this.onTap,
  });

  final EdgeInsets padding;
  final double minHeight;
  final bool isFullWidth;
  final Color focusRingColor;
  final BoxDecoration Function(bool pressed) buildDecoration;
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableContainer> createState() => _PressableContainerState();
}

class _PressableContainerState extends State<_PressableContainer> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(covariant _PressableContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A button that turns disabled mid-press must not stay scaled down.
    if (!_enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: _enabled,
      mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: widget.isFullWidth ? double.infinity : null,
            constraints: BoxConstraints(minHeight: widget.minHeight),
            padding: widget.padding,
            decoration: widget.buildDecoration(_pressed),
            foregroundDecoration: _focused
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: widget.focusRingColor, width: 2),
                  )
                : null,
            child: Align(
              alignment: Alignment.center,
              widthFactor: widget.isFullWidth ? null : 1.0,
              heightFactor: 1.0,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
