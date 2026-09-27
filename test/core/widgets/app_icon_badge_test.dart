import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppIconBadge),
        matching: find.byType(Container),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  group('sizes', () {
    const expected = {
      AppIconBadgeSize.sm: (32.0, 16.0),
      AppIconBadgeSize.md: (40.0, 20.0),
      AppIconBadgeSize.lg: (56.0, 28.0),
    };

    for (final entry in expected.entries) {
      testWidgets('positive: ${entry.key.name} renders its box and icon size',
          (tester) async {
        await tester.pumpWidget(
          wrap(AppIconBadge(icon: Icons.star_rounded, size: entry.key)),
        );

        expect(
          tester.getSize(find.byType(AppIconBadge)),
          Size(entry.value.$1, entry.value.$1),
        );
        expect(tester.widget<Icon>(find.byType(Icon)).size, entry.value.$2);
      });
    }

    testWidgets('edge: circular uses a circle shape', (tester) async {
      await tester.pumpWidget(
        wrap(const AppIconBadge(icon: Icons.star_rounded, circular: true)),
      );

      expect(decorationOf(tester).shape, BoxShape.circle);
      expect(decorationOf(tester).borderRadius, isNull);
    });
  });

  group('tones', () {
    const expected = {
      AppIconBadgeTone.primary: (AppColors.primaryFixed, AppColors.primary),
      AppIconBadgeTone.success: (
        AppColors.successContainer,
        AppColors.success,
      ),
      AppIconBadgeTone.error: (AppColors.errorContainer, AppColors.error),
      AppIconBadgeTone.warning: (
        AppColors.warningContainer,
        AppColors.warning,
      ),
      AppIconBadgeTone.gold: (
        AppColors.tertiaryFixed,
        AppColors.tertiaryStrong,
      ),
      AppIconBadgeTone.neutral: (
        AppColors.surfaceContainerHigh,
        AppColors.onSurfaceVariant,
      ),
    };

    for (final entry in expected.entries) {
      testWidgets('positive: ${entry.key.name} uses its fill and icon colour',
          (tester) async {
        await tester.pumpWidget(
          wrap(AppIconBadge(icon: Icons.star_rounded, tone: entry.key)),
        );

        expect(decorationOf(tester).color, entry.value.$1);
        expect(tester.widget<Icon>(find.byType(Icon)).color, entry.value.$2);
      });
    }
  });

  testWidgets('edge: isLoading swaps the icon for one spinner', (tester) async {
    await tester.pumpWidget(
      wrap(const AppIconBadge(icon: Icons.star_rounded, isLoading: true)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('negative: with no label the badge is decorative',
      (tester) async {
    await tester.pumpWidget(
      wrap(const AppIconBadge(icon: Icons.star_rounded)),
    );

    // The outermost ExcludeSemantics is the badge's (Icon adds its own).
    final exclude = tester
        .widgetList<ExcludeSemantics>(
          find.descendant(
            of: find.byType(AppIconBadge),
            matching: find.byType(ExcludeSemantics),
          ),
        )
        .first;
    expect(exclude.excluding, isTrue);
  });

  testWidgets('positive: a semanticLabel is exposed as an image',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        const AppIconBadge(icon: Icons.star_rounded, semanticLabel: 'Gold tier'),
      ),
    );

    expect(
      tester.getSemantics(find.byType(AppIconBadge)),
      isSemantics(label: 'Gold tier', isImage: true),
    );
    handle.dispose();
  });
}
