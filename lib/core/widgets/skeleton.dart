import 'package:flutter/material.dart';

import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';

/// Animates a light highlight sweeping across its child, giving skeleton
/// placeholders a "shimmer" loading effect. Wrap a tree of [SkeletonBox]es.
///
/// - Set [onDark] on blue or dark surfaces (pair with `SkeletonBox(onDark:)`).
/// - With reduced motion on, the child is shown still.
/// - The shimmer is excluded from semantics; callers label the loading region.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child, this.onDark = false});

  final Widget child;

  /// Pulses the child's opacity instead of painting a light band over it.
  final bool onDark;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) return ExcludeSemantics(child: widget.child);

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            // Light: paint the band over the blocks. Dark: only alpha matters,
            // so the translucent blocks pulse between half and full strength.
            blendMode: widget.onDark ? BlendMode.dstIn : BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: widget.onDark
                    ? const [
                        Color(0x80FFFFFF),
                        Color(0xFFFFFFFF),
                        Color(0x80FFFFFF),
                      ]
                    : const [
                        AppColors.surfaceContainerHigh,
                        AppColors.surfaceContainerLowest,
                        AppColors.surfaceContainerHigh,
                      ],
                stops: const [0.1, 0.5, 0.9],
                transform: _SlideGradient(_controller.value),
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Slides a gradient horizontally from off-screen left to off-screen right.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.value);

  final double value;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (value * 2 - 1);
    return Matrix4.translationValues(dx, 0, 0);
  }
}

/// A single rounded placeholder block for use inside a [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
    this.onDark = false,
  });

  final double? width;
  final double height;
  final double radius;

  /// Use on blue or dark surfaces: a translucent white block.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: onDark
            ? AppColors.onPrimary.withValues(alpha: 0.24)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
