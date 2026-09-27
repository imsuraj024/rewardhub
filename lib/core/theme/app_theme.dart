import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      // Primary
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryFixed,
      // Secondary (mapped to primaryFixed tones)
      secondary: AppColors.primaryFixed,
      onSecondary: AppColors.onPrimaryFixed,
      secondaryContainer: AppColors.primaryFixed,
      onSecondaryContainer: AppColors.onPrimaryFixed,
      // Tertiary — Gold / Value layer
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiaryFixed,
      tertiaryContainer: AppColors.tertiaryFixed,
      onTertiaryContainer: AppColors.onTertiaryFixed,
      // Error
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      // Surface
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      // Outline
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      shadow: AppColors.shadow,
      scrim: AppColors.shadow,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.onInverseSurface,
      inversePrimary: AppColors.inversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      // ── Typography ──────────────────────────────────────────────────────────
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: AppTextStyles.displayLg,
        displayMedium: AppTextStyles.displayMd,
        displaySmall: AppTextStyles.displaySm,
        headlineLarge: AppTextStyles.headlineLg,
        headlineMedium: AppTextStyles.headlineMd,
        headlineSmall: AppTextStyles.headlineSm,
        titleLarge: AppTextStyles.titleLg,
        titleMedium: AppTextStyles.titleMd,
        titleSmall: AppTextStyles.titleSm,
        bodyLarge: AppTextStyles.bodyLg,
        bodyMedium: AppTextStyles.bodyMd,
        bodySmall: AppTextStyles.bodySm,
        labelLarge: AppTextStyles.labelLg,
        labelMedium: AppTextStyles.labelMd,
        labelSmall: AppTextStyles.labelSm,
      ),
      // ── Cards ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        shadowColor: AppColors.shadowColor,
        margin: EdgeInsets.zero,
      ),
      // ── Elevated Button (Primary CTA) ────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(AppColors.onPrimary),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          textStyle: WidgetStateProperty.all(AppTextStyles.labelMd),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
      // ── Outlined Button (Secondary / Ghost) ──────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          textStyle: WidgetStateProperty.all(AppTextStyles.labelMd),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.outline, width: 1),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
      // ── Text Button (Tertiary) ────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          textStyle: WidgetStateProperty.all(AppTextStyles.labelMd),
        ),
      ),
      // ── Input Fields ─────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        // Long validator messages wrap at 320 dp instead of being cut off.
        errorMaxLines: 3,
        errorStyle: AppTextStyles.bodySm.copyWith(color: AppColors.error),
        labelStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      // ── Checkbox ─────────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: AppColors.outline, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
      ),
      // ── Chips ────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.primaryFixed,
        labelStyle: AppTextStyles.labelMd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      // ── App Bar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTextStyles.titleLg,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      // ── Bottom Nav (Material 3 NavigationBar) ────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadowColor,
        elevation: 3,
        height: 64,
        indicatorColor: AppColors.primaryFixed,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTextStyles.labelSm.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      // ── Progress Indicator ───────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceContainerHighest,
        linearMinHeight: 12, // thick 12px bars per DESIGN.md
      ),
      // ── Divider — hidden by default (No-Line Rule) ───────────────────────────
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
    );
  }
}
