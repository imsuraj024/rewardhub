import 'package:flutter/material.dart';

/// RewardHub color palette — derived from DESIGN.md
/// Governed by the 60:30:10 surface/primary/accent ratio.
abstract final class AppColors {
  // ── Dominant (60%) ──────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFE8EAED);
  static const Color surfaceContainerHigh = Color(0xFFE4E6E9);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceBright = Color(0xFFF9FBFD);

  // ── Secondary (30%) — Brand Blue ────────────────────────────────────────────
  static const Color primary = Color(0xFF0040A1);
  static const Color primaryContainer = Color(0xFF0056D2);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryFixed = Color(0xFF001849);

  // ── Accent (10%) — Value / Gold ──────────────────────────────────────────────
  static const Color tertiary = Color(0xFFFFB77D);
  static const Color tertiaryFixedDim = Color(0xFFFFB77D);
  static const Color tertiaryFixed = Color(0xFFFFDCC2);
  static const Color onTertiaryFixed = Color(0xFF2D1600);

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color success = Color(0xFF1E7B34);
  static const Color successContainer = Color(0xFFC7F5CE);
  static const Color onSuccessContainer = Color(0xFF002108);

  static const Color warning = Color(0xFFB26A00);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color onWarningContainer = Color(0xFF2A1800);

  static const Color info = primary;
  static const Color infoContainer = primaryFixed;
  static const Color onInfoContainer = onPrimaryFixed;

  // ── On-surface / Text ────────────────────────────────────────────────────────
  /// Use this instead of pure black. Keeps contrast high but feels professional.
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF43474E);

  // ── Outline ──────────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF73777F);
  static const Color outlineVariant = Color(0xFFC3C6D6);

  // ── Shadow ───────────────────────────────────────────────────────────────────
  /// Ambient shadow spec: 0px 12px 32px rgba(25,28,30,0.06)
  static const Color shadow = Color(0xFF191C1E);
  static const shadowColor = Color(0x0F191C1E); // 6% opacity

  // ── Gradient helpers ─────────────────────────────────────────────────────────
  /// Primary CTA gradient — 135° from primary → primaryContainer
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    transform: GradientRotation(135 * 3.14159265 / 180),
    colors: [primary, primaryContainer],
  );

  // ── Ghost border (accessibility fallback) ────────────────────────────────────
  /// outlineVariant at 15% opacity — "felt, not seen"
  static const Color ghostBorder = Color(0x26C3C6D6); // ~15% of outlineVariant
}
