import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// RewardHub typography — dual-font editorial strategy from DESIGN.md
///
/// Display / Headlines → Manrope  (the "Voice")
/// Body / Labels       → Inter    (the "Engine")
abstract final class AppTextStyles {
  // ── Manrope — Display & Headlines ───────────────────────────────────────────

  static TextStyle get displayLg => GoogleFonts.manrope(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: AppColors.onSurface,
      );

  static TextStyle get displayMd => GoogleFonts.manrope(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: AppColors.onSurface,
      );

  static TextStyle get displaySm => GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineLg => GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineSm => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: AppColors.onSurface,
      );

  static TextStyle get titleLg => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: AppColors.onSurface,
      );

  static TextStyle get titleMd => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: AppColors.onSurface,
      );

  static TextStyle get titleSm => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.onSurface,
      );

  // ── Inter — Body & Labels ────────────────────────────────────────────────────

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: AppColors.onSurface,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.onSurface,
      );

  /// Used for button labels per DESIGN.md
  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.onSurface,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.onSurfaceVariant,
      );

  // ── Role tokens ──────────────────────────────────────────────────────────────
  // Use these instead of per-widget fontSize / fontWeight overrides.

  /// Points number on PointsBalanceCard (sits on primaryGradient).
  static TextStyle get pointsHero => GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
        color: AppColors.onPrimary,
      );

  /// Signed points amount in transaction rows. Tabular figures line up.
  static TextStyle get amount => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: AppColors.onSurface,
      );

  /// Section heading on a screen ("Transaction history", "Payment details").
  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
        color: AppColors.onSurface,
      );

  /// Title of a bottom sheet or dialog.
  static TextStyle get sheetTitle => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.onSurface,
      );

  /// First line of a list row, settings tile, FAQ question or transaction.
  static TextStyle get listTitle => titleSm;

  /// AppTopBar title.
  static TextStyle get appBarTitle => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );

  /// Label above a form field (sentence case).
  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.onSurfaceVariant,
      );

  /// Small emphasised label above content ("Step 1 of 3", "How to earn points").
  /// Strings stay sentence case. Flutter has no text-transform, so there is no
  /// uppercase variant.
  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.onSurfaceVariant,
      );
}
