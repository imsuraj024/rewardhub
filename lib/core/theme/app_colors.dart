import 'package:flutter/material.dart';

/// RewardHub color palette — derived from DESIGN.md
/// Governed by the 60:30:10 surface/primary/accent ratio.
///
/// Which token to use (contrast ratios are WCAG 2.x):
///
/// | Need | Token (ratio) | Replaces |
/// |---|---|---|
/// | Gold text/icons on light surfaces | [tertiaryStrong] (≥ 4.99) | #B76E00, #D97706, #EA580C, #F59E0B, #FFB800 |
/// | Gold tint fill (badge, chip) | [tertiaryFixed] | #FFFBEB, #FEF3C7 |
/// | Warm card background | [tertiarySurface] | #FFFBF0 |
/// | Large gold fills and coin graphics only | [tertiary] (1.70 on white, so no text or icons) | #FFB800 fills |
/// | Text on [tertiary] / [tertiaryFixed] | [onTertiaryFixed] (10.05 / 13.27) | #4E2C00 |
/// | Credit / success text and icons | [success] (5.33 on white) | #16A34A (3.30), #2E7D32 |
/// | Success tint | [successContainer], with icons in [success] (4.41) and text in [onSuccessContainer] (14.23) | #E8F5E9, #DCFCE7, #C8E6C9 |
/// | Debit / destructive | [error] (6.46), [errorContainer] | #DC2626, #FEF2F2, #FFEBEE |
/// | Blue tints | [primaryFixed], with [primary] text/icons on it (7.23) | #EFF6FF, #DBEAFE, #E8F0FE |
/// | Hero cards | [primaryGradient], with all foreground [onPrimary] at full opacity (6.44–9.34) | indigo and Tailwind blues; white with alpha on text; green on blue |
/// | Dark camera panel | [onSurface] background, text [onPrimary] (17.13), actions [primaryFixed] (13.25) or `AppButton.inverted` | #191A1E; [primary] text on dark (1.86) |
/// | Dark promo surfaces | [onSurface] → [inverseSurface], text [onInverseSurface] (≥ 11.57), accents [inversePrimary] (≥ 7.71) | #121826, #1E293B, #38BDF8 |
/// | Boundaries that identify a control (inputs, checkbox, outline buttons, dashed upload slots, position dots) | [outline] (4.49 white, 4.26 surface, 4.07 surfaceContainerLow) | [outlineVariant], [ghostBorder], alpha outlines |
/// | Decorative dividers and handles | [outlineVariant] | — |
/// | Scrims | [scrim] | `Colors.black*`, `0x99000000` |
/// | White | [onPrimary] (foreground on blue or dark), [surfaceContainerLowest] (as a surface) | `Colors.white` |
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

  /// Gold for TEXT and ICONS on light surfaces (points, badges, gold labels).
  /// 6.45:1 on white, 6.11 on surface, 5.85 on surfaceContainerLow,
  /// 4.99 on tertiaryFixed, 6.08 on tertiarySurface.
  static const Color tertiaryStrong = Color(0xFF8A5100);

  /// Lightest gold surface for warm cards and the gold banner.
  static const Color tertiarySurface = Color(0xFFFFF7F0);

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

  // ── Inverse — dark panels on the light theme ─────────────────────────────────
  static const Color inverseSurface = Color(0xFF2E3133);
  static const Color onInverseSurface = Color(0xFFEFF1F3);
  static const Color inversePrimary = Color(0xFFB0C6FF);

  // ── Shadow ───────────────────────────────────────────────────────────────────
  /// Ambient shadow spec: 0px 12px 32px rgba(25,28,30,0.06)
  static const Color shadow = Color(0xFF191C1E);
  static const shadowColor = Color(0x0F191C1E); // 6% opacity

  // ── Scrim ────────────────────────────────────────────────────────────────────
  /// onSurface at 72%. Dims the camera preview around the scan window, backs
  /// white text on photos, and backs blocking progress overlays.
  /// White text on it is ≥ 6.74:1 even over a pure-white image.
  static const Color scrim = Color(0xB8191C1E);

  // ── Gradient helpers ─────────────────────────────────────────────────────────
  /// Primary CTA gradient — 135° from primary → primaryContainer
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    transform: GradientRotation(135 * 3.14159265 / 180),
    colors: [primary, primaryContainer],
  );

  /// Background of every auth screen (login, OTP, registration steps).
  static const LinearGradient authBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8EDF8), Color(0xFFD6E0F5)],
  );

  // ── Ghost border (accessibility fallback) ────────────────────────────────────
  /// Decorative only. Never the only boundary of a control (1.07:1). Use [outline].
  static const Color ghostBorder = Color(0x26C3C6D6); // ~15% of outlineVariant
}
