import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/theme/app_colors.dart';

void main() {
  test('positive: surface / primary / accent constants are defined colors', () {
    expect(AppColors.surface, isA<Color>());
    expect(AppColors.primary, const Color(0xFF0040A1));
    expect(AppColors.tertiary, const Color(0xFFFFB77D));
    expect(AppColors.onPrimary, const Color(0xFFFFFFFF));
  });

  test('positive: semantic colors are defined', () {
    expect(AppColors.error, isA<Color>());
    expect(AppColors.success, isA<Color>());
    expect(AppColors.warning, isA<Color>());
    // info aliases primary.
    expect(AppColors.info, AppColors.primary);
    expect(AppColors.infoContainer, AppColors.primaryFixed);
    expect(AppColors.onInfoContainer, AppColors.onPrimaryFixed);
  });

  test('positive: surface container ramp is defined', () {
    expect(AppColors.surfaceContainerLowest, isA<Color>());
    expect(AppColors.surfaceContainerLow, isA<Color>());
    expect(AppColors.surfaceContainer, isA<Color>());
    expect(AppColors.surfaceContainerHigh, isA<Color>());
    expect(AppColors.surfaceContainerHighest, isA<Color>());
    expect(AppColors.surfaceBright, isA<Color>());
  });

  test('positive: outline, text and shadow tokens are defined', () {
    expect(AppColors.outline, isA<Color>());
    expect(AppColors.outlineVariant, isA<Color>());
    expect(AppColors.onSurface, isA<Color>());
    expect(AppColors.onSurfaceVariant, isA<Color>());
    expect(AppColors.shadow, isA<Color>());
    expect(AppColors.ghostBorder, isA<Color>());
  });

  test('edge: shadowColor is a low-alpha shade of the shadow', () {
    // 0x0F alpha == ~6% opacity per the spec comment.
    expect(AppColors.shadowColor, const Color(0x0F191C1E));
    expect(AppColors.shadowColor.a, lessThan(0.1));
  });

  test('edge: primaryGradient is a two-stop rotated linear gradient', () {
    const gradient = AppColors.primaryGradient;
    expect(gradient, isA<LinearGradient>());
    expect(gradient.colors, [AppColors.primary, AppColors.primaryContainer]);
    expect(gradient.transform, isA<GradientRotation>());
  });
}
