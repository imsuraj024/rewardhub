import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_spacing.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';

/// Preset color styles for creative text & split banners.
enum AppBannerStyle { primary, gold, success, dark, subtle }

/// A creative, versatile banner widget with multiple visual variants:
/// - [AppBanner.image]: Full visual image banner with optional overlay text and tag.
/// - [AppBanner.text]: High-impact typographic announcement card with gradient themes.
/// - [AppBanner.split]: Rich hybrid card pairing punchy copy and a graphic illustration/icon.
class AppBanner extends StatelessWidget {
  const AppBanner._({super.key, required this.child, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? margin;

  // ── Factory: Image Banner ──────────────────────────────────────────────────

  /// Creates a full-width visual image banner.
  ///
  /// Supports network images or local assets, with optional floating badge,
  /// dark scrim gradient overlay, title, and action button.
  factory AppBanner.image({
    Key? key,
    required String imageUrl,
    bool isNetwork = true,
    double height = 150,
    String? badgeText,
    String? title,
    String? subtitle,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return AppBanner._(
      key: key,
      margin: margin,
      child: _ImageBannerContent(
        imageUrl: imageUrl,
        isNetwork: isNetwork,
        height: height,
        badgeText: badgeText,
        title: title,
        subtitle: subtitle,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
    );
  }

  // ── Factory: Text / Announcement Banner ────────────────────────────────────

  /// Creates an editorial announcement banner with rich gradient background,
  /// badge chip, headline, subtitle, and CTA.
  factory AppBanner.text({
    Key? key,
    required String title,
    required String subtitle,
    String? badgeText,
    IconData? icon,
    AppBannerStyle style = AppBannerStyle.primary,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return AppBanner._(
      key: key,
      margin: margin,
      child: _TextBannerContent(
        title: title,
        subtitle: subtitle,
        badgeText: badgeText,
        icon: icon,
        style: style,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
    );
  }

  // ── Factory: Split / Hybrid Banner ─────────────────────────────────────────

  /// Creates a creative hybrid banner with text on the left and an
  /// illustration / 3D icon / graphic container on the right.
  factory AppBanner.split({
    Key? key,
    required String title,
    required String subtitle,
    required Widget graphic,
    String? badgeText,
    AppBannerStyle style = AppBannerStyle.primary,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return AppBanner._(
      key: key,
      margin: margin,
      child: _SplitBannerContent(
        title: title,
        subtitle: subtitle,
        graphic: graphic,
        badgeText: badgeText,
        style: style,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (margin != null) {
      return Container(margin: margin, child: child);
    }
    return child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Image Banner Content
// ─────────────────────────────────────────────────────────────────────────────

class _ImageBannerContent extends StatelessWidget {
  const _ImageBannerContent({
    required this.imageUrl,
    required this.isNetwork,
    required this.height,
    required this.borderRadius,
    this.badgeText,
    this.title,
    this.subtitle,
  });

  final String imageUrl;
  final bool isNetwork;
  final double height;
  final BorderRadius borderRadius;
  final String? badgeText;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final banner = Container(
      height: height,
      decoration: BoxDecoration(borderRadius: borderRadius),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (isNetwork)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceContainerHigh,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.onSurfaceVariant,
                      size: 36,
                    ),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.surfaceContainerHigh,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              )
            else
              Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceContainerHigh,
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

            // Gradient Scrim overlay if text is present
            if (title != null || subtitle != null || badgeText != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.onSurface.withValues(alpha: 0.15),
                      AppColors.scrim,
                    ],
                  ),
                ),
              ),

            // Tap ripple & Content
            Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Badge
                    if (badgeText != null)
                      _BannerBadge(
                        text: badgeText!,
                        backgroundColor: AppColors.primary,
                        textColor: AppColors.onPrimary,
                      ),
                    const Spacer(),
                    // Bottom copy + CTA
                    if (title != null)
                      Text(
                        title!,
                        style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // With no copy on top, the image itself is the promotion.
    if (title == null && subtitle == null) {
      return Semantics(image: true, label: 'Promotion', child: banner);
    }
    return banner;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Text Announcement Banner Content
// ─────────────────────────────────────────────────────────────────────────────

class _TextBannerContent extends StatelessWidget {
  const _TextBannerContent({
    required this.title,
    required this.subtitle,
    required this.style,
    required this.borderRadius,
    this.badgeText,
    this.icon,
  });

  final String title;
  final String subtitle;
  final AppBannerStyle style;
  final BorderRadius borderRadius;
  final String? badgeText;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = _BannerThemeData.fromStyle(style);

    return Container(
      decoration: BoxDecoration(
        gradient: theme.gradient,
        color: theme.backgroundColor,
        borderRadius: borderRadius,
        border: theme.border,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row: Icon / Badge always on top
              if (icon != null || badgeText != null) ...[
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.iconContainerColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 14, color: theme.iconColor),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (badgeText != null)
                      _BannerBadge(
                        text: badgeText!,
                        backgroundColor: theme.badgeBgColor,
                        textColor: theme.badgeTextColor,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Title
              Flexible(
                child: Text(
                  title,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),

              // Subtitle
              Flexible(
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodySm.copyWith(
                    color: theme.subtitleColor,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Split Hybrid Banner Content
// ─────────────────────────────────────────────────────────────────────────────

class _SplitBannerContent extends StatelessWidget {
  const _SplitBannerContent({
    required this.title,
    required this.subtitle,
    required this.graphic,
    required this.style,
    required this.borderRadius,
    this.badgeText,
  });

  final String title;
  final String subtitle;
  final Widget graphic;
  final AppBannerStyle style;
  final BorderRadius borderRadius;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final theme = _BannerThemeData.fromStyle(style);

    return Container(
      decoration: BoxDecoration(
        gradient: theme.gradient,
        color: theme.backgroundColor,
        borderRadius: borderRadius,
        border: theme.border,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Badge always on top
                if (badgeText != null) ...[
                  _BannerBadge(
                    text: badgeText!,
                    backgroundColor: theme.badgeBgColor,
                    textColor: theme.badgeTextColor,
                  ),
                  const SizedBox(height: 10),
                ],

                Row(
                  children: [
                    // Left Column: Copy
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.titleMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: AppTextStyles.bodySm.copyWith(
                              color: theme.subtitleColor,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Right Column: Graphic Widget
                    Expanded(flex: 4, child: Center(child: graphic)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Banner Carousel (Auto-Sliding / Paged Banner Container)
// ─────────────────────────────────────────────────────────────────────────────

/// Animated, auto-sliding banner carousel with dots indicator.
class AppBannerCarousel extends StatefulWidget {
  const AppBannerCarousel({
    super.key,
    required this.banners,
    this.autoPlayDuration = const Duration(seconds: 4),
    this.autoPlay = true,
    this.height,
    this.viewportFraction = 1.0,
    this.itemSpacing = 8.0,
  });

  final List<Widget> banners;
  final Duration autoPlayDuration;
  final bool autoPlay;
  final double? height;
  final double viewportFraction;
  final double itemSpacing;

  @override
  State<AppBannerCarousel> createState() => _AppBannerCarouselState();
}

class _AppBannerCarouselState extends State<AppBannerCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;

  /// Auto-play is off with reduced motion or a screen reader, since moving
  /// content can't be read or paused otherwise.
  bool _autoPlayAllowed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _autoPlayAllowed =
        widget.autoPlay &&
        widget.banners.length > 1 &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    if (_autoPlayAllowed) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  // A finger on the carousel pauses it; lifting it restarts the countdown.
  void _pause(PointerEvent _) => _timer?.cancel();

  void _resume(PointerEvent _) {
    if (_autoPlayAllowed) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayDuration, (_) {
      if (!mounted || widget.banners.isEmpty) return;
      final nextPage = (_currentIndex + 1) % widget.banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    if (widget.banners.length == 1) return widget.banners.first;

    // Grows with the text size (up to 1.5x) so larger text isn't clipped.
    final textGrowth = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(
      1.0,
      1.5,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: (widget.height ?? 150) * textGrowth,
          child: Listener(
            onPointerDown: _pause,
            onPointerUp: _resume,
            onPointerCancel: _resume,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.banners.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.itemSpacing > 0
                        ? widget.itemSpacing / 2
                        : 0,
                  ),
                  child: MergeSemantics(
                    child: Semantics(
                      label: 'Banner ${index + 1} of ${widget.banners.length}',
                      child: widget.banners[index],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Dots Indicator — position is announced per banner instead.
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (index) {
              final isSelected = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.outline,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable UI Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _BannerBadge extends StatelessWidget {
  const _BannerBadge({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        // Badge text comes from Remote Config; the caps are a visual style.
        text.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _BannerThemeData {
  const _BannerThemeData({
    required this.gradient,
    required this.backgroundColor,
    required this.textColor,
    required this.subtitleColor,
    required this.iconColor,
    required this.iconContainerColor,
    required this.badgeBgColor,
    required this.badgeTextColor,
    this.border,
  });

  final Gradient? gradient;
  final Color? backgroundColor;
  final Color textColor;
  final Color subtitleColor;
  final Color iconColor;
  final Color iconContainerColor;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final BoxBorder? border;

  /// Every text/badge pair meets 4.5:1 (ratios in the design spec, DS-16).
  factory _BannerThemeData.fromStyle(AppBannerStyle style) {
    switch (style) {
      case AppBannerStyle.primary:
        return _BannerThemeData(
          gradient: AppColors.primaryGradient,
          backgroundColor: null,
          textColor: AppColors.onPrimary,
          subtitleColor: AppColors.onPrimary,
          iconColor: AppColors.onPrimary,
          iconContainerColor: AppColors.onPrimary.withValues(alpha: 0.2),
          badgeBgColor: AppColors.onPrimary,
          badgeTextColor: AppColors.primary,
        );

      case AppBannerStyle.gold:
        return _BannerThemeData(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.tertiarySurface, AppColors.tertiaryFixed],
          ),
          backgroundColor: null,
          textColor: AppColors.onTertiaryFixed,
          subtitleColor: AppColors.tertiaryStrong,
          iconColor: AppColors.tertiaryStrong,
          iconContainerColor: AppColors.surfaceContainerLowest,
          badgeBgColor: AppColors.tertiaryStrong,
          badgeTextColor: AppColors.onPrimary,
          border: Border.all(color: AppColors.tertiary, width: 1),
        );

      case AppBannerStyle.success:
        return const _BannerThemeData(
          gradient: null,
          backgroundColor: AppColors.successContainer,
          textColor: AppColors.onSuccessContainer,
          subtitleColor: AppColors.onSurfaceVariant,
          iconColor: AppColors.success,
          iconContainerColor: AppColors.surfaceContainerLowest,
          badgeBgColor: AppColors.success,
          badgeTextColor: AppColors.onPrimary,
        );

      case AppBannerStyle.dark:
        return _BannerThemeData(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.onSurface, AppColors.inverseSurface],
          ),
          backgroundColor: null,
          textColor: AppColors.onInverseSurface,
          subtitleColor: AppColors.outlineVariant,
          iconColor: AppColors.inversePrimary,
          iconContainerColor: AppColors.onInverseSurface.withValues(
            alpha: 0.12,
          ),
          badgeBgColor: AppColors.inversePrimary,
          badgeTextColor: AppColors.onPrimaryFixed,
        );

      case AppBannerStyle.subtle:
        return _BannerThemeData(
          gradient: null,
          backgroundColor: AppColors.surfaceContainerLowest,
          textColor: AppColors.onSurface,
          subtitleColor: AppColors.onSurfaceVariant,
          iconColor: AppColors.primary,
          iconContainerColor: AppColors.primaryFixed,
          badgeBgColor: AppColors.primaryFixed,
          badgeTextColor: AppColors.primary,
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        );
    }
  }
}
