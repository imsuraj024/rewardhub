import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_theme.dart';

void main() {
  // AppTheme wires GoogleFonts into its text theme, triggering an (unawaited)
  // async font load. Running inside `testWidgets` lets the binding absorb those
  // font-load errors the same way a real widget build does.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('positive: light theme is a Material 3 ThemeData',
      (tester) async {
    final theme = AppTheme.light;
    expect(theme, isA<ThemeData>());
    expect(theme.useMaterial3, isTrue);
  });

  testWidgets('positive: light color scheme uses the brand palette',
      (tester) async {
    final scheme = AppTheme.light.colorScheme;
    expect(scheme.brightness, Brightness.light);
    expect(scheme.primary, AppColors.primary);
    expect(scheme.onPrimary, AppColors.onPrimary);
    expect(scheme.tertiary, AppColors.tertiary);
    expect(scheme.error, AppColors.error);
    expect(scheme.surface, AppColors.surface);
  });

  testWidgets('positive: scaffold background matches the surface token',
      (tester) async {
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.surface);
  });

  testWidgets('edge: component sub-themes are configured', (tester) async {
    final theme = AppTheme.light;
    expect(theme.cardTheme.color, AppColors.surfaceContainerLowest);
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.appBarTheme.elevation, 0);
    expect(theme.progressIndicatorTheme.color, AppColors.primary);
    expect(theme.dividerTheme.color, Colors.transparent);
  });

  testWidgets('positive: inputs show a visible outline, focus and error ring',
      (tester) async {
    final input = AppTheme.light.inputDecorationTheme;
    final enabled = input.enabledBorder as OutlineInputBorder;
    final focused = input.focusedBorder as OutlineInputBorder;
    final error = input.errorBorder as OutlineInputBorder;
    final focusedError = input.focusedErrorBorder as OutlineInputBorder;
    final disabled = input.disabledBorder as OutlineInputBorder;

    expect(enabled.borderSide.color, AppColors.outline);
    expect(enabled.borderSide.width, 1);
    expect(focused.borderSide.color, AppColors.primary);
    expect(focused.borderSide.width, 2);
    expect(error.borderSide.color, AppColors.error);
    expect(error.borderSide.width, 1);
    expect(focusedError.borderSide.color, AppColors.error);
    expect(focusedError.borderSide.width, 2);
    expect(disabled.borderSide.color, AppColors.outlineVariant);
    expect(input.errorMaxLines, 3);
  });

  testWidgets('positive: checkbox and outlined button have visible borders',
      (tester) async {
    final theme = AppTheme.light;
    expect(
      theme.checkboxTheme.side,
      const BorderSide(color: AppColors.outline, width: 2),
    );
    expect(
      theme.checkboxTheme.fillColor?.resolve({WidgetState.selected}),
      AppColors.primary,
    );
    expect(theme.checkboxTheme.fillColor?.resolve({}), Colors.transparent);
    expect(
      theme.outlinedButtonTheme.style?.side?.resolve({}),
      const BorderSide(color: AppColors.outline, width: 1),
    );
  });

  testWidgets('positive: color scheme carries the inverse set', (tester) async {
    final scheme = AppTheme.light.colorScheme;
    expect(scheme.inverseSurface, AppColors.inverseSurface);
    expect(scheme.onInverseSurface, AppColors.onInverseSurface);
    expect(scheme.inversePrimary, AppColors.inversePrimary);
  });

  testWidgets('edge: text theme wires up the app text styles', (tester) async {
    final textTheme = AppTheme.light.textTheme;
    expect(textTheme.displayLarge?.fontSize, 57);
    expect(textTheme.titleLarge?.fontSize, 22);
    expect(textTheme.bodyMedium?.fontSize, 14);
    expect(textTheme.labelSmall?.fontSize, 11);
  });

  testWidgets('positive: theme applies cleanly to a MaterialApp',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Text('themed')),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('themed'), findsOneWidget);
  });
}
