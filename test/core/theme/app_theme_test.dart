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
    expect(theme.progressIndicatorTheme.color, AppColors.tertiary);
    expect(theme.dividerTheme.color, Colors.transparent);
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
