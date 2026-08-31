import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_text_styles.dart';

void main() {
  // These styles are backed by GoogleFonts, which kicks off an (unawaited)
  // async font load. Running the assertions inside `testWidgets` lets the test
  // binding absorb those font-load errors the same way real widget builds do.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('positive: display styles expose their design sizes',
      (tester) async {
    expect(AppTextStyles.displayLg.fontSize, 57);
    expect(AppTextStyles.displayMd.fontSize, 45);
    expect(AppTextStyles.displaySm.fontSize, 36);
  });

  testWidgets('positive: headline styles expose their design sizes',
      (tester) async {
    expect(AppTextStyles.headlineLg.fontSize, 32);
    expect(AppTextStyles.headlineMd.fontSize, 28);
    expect(AppTextStyles.headlineSm.fontSize, 24);
  });

  testWidgets('positive: title styles expose their design sizes',
      (tester) async {
    expect(AppTextStyles.titleLg.fontSize, 22);
    expect(AppTextStyles.titleMd.fontSize, 16);
    expect(AppTextStyles.titleSm.fontSize, 14);
  });

  testWidgets('positive: body styles expose their design sizes',
      (tester) async {
    expect(AppTextStyles.bodyLg.fontSize, 16);
    expect(AppTextStyles.bodyMd.fontSize, 14);
    expect(AppTextStyles.bodySm.fontSize, 12);
  });

  testWidgets('positive: label styles expose their design sizes',
      (tester) async {
    expect(AppTextStyles.labelLg.fontSize, 14);
    expect(AppTextStyles.labelMd.fontSize, 12);
    expect(AppTextStyles.labelSm.fontSize, 11);
  });

  testWidgets('edge: styles carry the expected font weights', (tester) async {
    expect(AppTextStyles.displayLg.fontWeight, FontWeight.w700);
    expect(AppTextStyles.titleLg.fontWeight, FontWeight.w600);
    expect(AppTextStyles.bodyMd.fontWeight, FontWeight.w400);
    expect(AppTextStyles.labelMd.fontWeight, FontWeight.w500);
  });

  testWidgets('edge: styles default to on-surface colors', (tester) async {
    expect(AppTextStyles.bodyLg.color, AppColors.onSurface);
    expect(AppTextStyles.bodySm.color, AppColors.onSurfaceVariant);
    expect(AppTextStyles.labelSm.color, AppColors.onSurfaceVariant);
  });

  testWidgets('edge: a style renders inside a Text widget without error',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text('sample', style: AppTextStyles.titleLg),
        ),
      ),
    );
    expect(find.text('sample'), findsOneWidget);
  });
}
