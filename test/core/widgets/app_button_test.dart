import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/widgets/app_button.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrap(Widget child, {double textScale = 1.0}) => MaterialApp(
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: app!,
        ),
        home: Scaffold(body: child),
      );

  void usePhoneWidth(WidgetTester tester, {double width = 320}) {
    tester.view.physicalSize = Size(width, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  // RenderParagraph has no public line metrics; divide by one line's height.
  int lineCount(RenderParagraph paragraph) => (paragraph.textSize.height /
          paragraph.getFullHeightForCaret(const TextPosition(offset: 0)))
      .round();

  BoxDecoration decorationOf(WidgetTester tester, [Finder? button]) {
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: button ?? find.byType(AppButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('renders its label', (tester) async {
    await tester.pumpWidget(
      wrap(AppButton(label: 'Continue', onPressed: () {})),
    );

    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('fires onPressed when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(AppButton(label: 'Tap', onPressed: () => taps++)),
    );

    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });

  testWidgets('does not fire while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(AppButton(label: 'Wait', isLoading: true, onPressed: () => taps++)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(taps, 0);
  });

  testWidgets('is inert when onPressed is null', (tester) async {
    await tester.pumpWidget(
      wrap(const AppButton(label: 'Disabled', onPressed: null)),
    );

    await tester.tap(find.byType(AppButton));
    // No callback to assert on — the test passes if the tap does not throw.
    expect(find.text('Disabled'), findsOneWidget);
  });

  group('semantics', () {
    testWidgets('positive: an enabled button is an enabled, tappable button',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(AppButton(label: 'Continue', onPressed: () {})),
      );

      expect(
        tester.getSemantics(find.byType(AppButton)),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          label: 'Continue',
        ),
      );
      handle.dispose();
    });

    testWidgets('edge: a loading button is disabled and says it is loading',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(AppButton(label: 'Wait', isLoading: true, onPressed: () {})),
      );

      expect(
        tester.getSemantics(find.byType(AppButton)),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Wait, loading',
        ),
      );
      handle.dispose();
    });

    testWidgets('negative: a null onPressed reports a disabled button',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(const AppButton(label: 'Disabled', onPressed: null)),
      );

      expect(
        tester.getSemantics(find.byType(AppButton)),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('edge: semanticLabel overrides the visible label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          AppButton(
            label: 'Go',
            semanticLabel: 'Go to page 3',
            onPressed: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(AppButton)),
        isSemantics(label: 'Go to page 3'),
      );
      handle.dispose();
    });
  });

  group('states', () {
    testWidgets('negative: a disabled primary button is grey, with no gradient',
        (tester) async {
      await tester.pumpWidget(
        wrap(const AppButton(label: 'Disabled', onPressed: null)),
      );

      final decoration = decorationOf(tester);
      expect(decoration.color, AppColors.surfaceContainerHigh);
      expect(decoration.gradient, isNull);
      expect(decoration.boxShadow, isNull);
      final text = tester.widget<Text>(find.text('Disabled'));
      expect(text.style?.color, AppColors.onSurfaceVariant);
    });

    testWidgets('positive: a loading primary button keeps its gradient',
        (tester) async {
      await tester.pumpWidget(
        wrap(AppButton(label: 'Wait', isLoading: true, onPressed: null)),
      );

      final decoration = decorationOf(tester);
      expect(decoration.gradient, AppColors.primaryGradient);
      final text = tester.widget<Text>(find.text('Wait'));
      expect(text.style?.color, AppColors.onPrimary);
    });

    testWidgets(
        'edge: a disabled outline button uses the outlineVariant border',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppButton(
            label: 'Back',
            onPressed: null,
            variant: AppButtonVariant.outline,
          ),
        ),
      );

      final border = decorationOf(tester).border! as Border;
      expect(border.top.color, AppColors.outlineVariant);
    });

    testWidgets('positive: sizes render at least their minimum height',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              AppButton(
                  key: const Key('sm'),
                  label: 'S',
                  size: AppButtonSize.sm,
                  onPressed: () {}),
              AppButton(key: const Key('md'), label: 'M', onPressed: () {}),
              AppButton(
                  key: const Key('lg'),
                  label: 'L',
                  size: AppButtonSize.lg,
                  onPressed: () {}),
            ],
          ),
        ),
      );

      expect(tester.getSize(find.byKey(const Key('sm'))).height,
          greaterThanOrEqualTo(40));
      expect(tester.getSize(find.byKey(const Key('md'))).height,
          greaterThanOrEqualTo(48));
      expect(tester.getSize(find.byKey(const Key('lg'))).height,
          greaterThanOrEqualTo(56));
    });
  });

  group('variants', () {
    testWidgets('edge: secondary renders exactly like outline', (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              AppButton(
                key: const Key('outline'),
                label: 'A',
                variant: AppButtonVariant.outline,
                onPressed: () {},
              ),
              AppButton(
                key: const Key('secondary'),
                label: 'A',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      final outline = decorationOf(tester, find.byKey(const Key('outline')));
      final secondary =
          decorationOf(tester, find.byKey(const Key('secondary')));
      expect(secondary, outline);
      expect((outline.border! as Border).top.color, AppColors.outline);
    });

    testWidgets('positive: tonal and destructive use their fills',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              AppButton(
                key: const Key('tonal'),
                label: 'Tonal',
                variant: AppButtonVariant.tonal,
                onPressed: () {},
              ),
              AppButton(
                key: const Key('destructive'),
                label: 'Delete',
                variant: AppButtonVariant.destructive,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(
        decorationOf(tester, find.byKey(const Key('tonal'))).color,
        AppColors.primaryFixed,
      );
      expect(
        tester.widget<Text>(find.text('Tonal')).style?.color,
        AppColors.primary,
      );
      expect(
        decorationOf(tester, find.byKey(const Key('destructive'))).color,
        AppColors.error,
      );
      expect(
        tester.widget<Text>(find.text('Delete')).style?.color,
        AppColors.onError,
      );
    });
  });

  group('layout', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('edge: full-width lg button fits 320 dp at ${scale}x text',
          (tester) async {
        usePhoneWidth(tester);
        await tester.pumpWidget(
          wrap(
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                label: 'Add bank account',
                size: AppButtonSize.lg,
                isFullWidth: true,
                leadingIcon: const Icon(Icons.account_balance_outlined),
                onPressed: () {},
              ),
            ),
            textScale: scale,
          ),
        );

        expect(tester.takeException(), isNull);
        // The test font's glyphs are full-em squares, far wider than Inter,
        // so at 2.0x the label legitimately hits its 2-line cap here.
        if (scale < 2.0) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text('Add bank account'),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
        }
      });
    }

    testWidgets('edge: at 2.0x text the label wraps and the button grows',
        (tester) async {
      usePhoneWidth(tester);
      Widget button() => Padding(
            padding: const EdgeInsets.all(24),
            child: AppButton(
              label: 'Add bank account',
              size: AppButtonSize.lg,
              isFullWidth: true,
              leadingIcon: const Icon(Icons.account_balance_outlined),
              onPressed: () {},
            ),
          );

      await tester.pumpWidget(wrap(button()));
      final oneLine = tester.getSize(find.byType(AppButton)).height;

      await tester.pumpWidget(wrap(button(), textScale: 2.0));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Add bank account'),
      );
      expect(lineCount(paragraph), 2);
      expect(
          tester.getSize(find.byType(AppButton)).height, greaterThan(oneLine));
    });

    testWidgets('edge: a 60-character label stops at 2 lines with an ellipsis',
        (tester) async {
      usePhoneWidth(tester);
      final label =
          'A very long call to action label that keeps going on and on.';
      expect(label.length, 60);
      await tester.pumpWidget(
        wrap(
          Padding(
            padding: const EdgeInsets.all(24),
            child: AppButton(label: label, isFullWidth: true, onPressed: () {}),
          ),
          textScale: 2.0,
        ),
      );

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(lineCount(paragraph), lessThanOrEqualTo(2));
    });

    testWidgets('edge: a non-full-width button is safe in an unbounded Row',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          Row(
            children: [
              const Text('Page'),
              AppButton(label: 'Go', size: AppButtonSize.sm, onPressed: () {}),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Go'), findsOneWidget);
    });
  });

  testWidgets('positive: Enter on a focused button calls onPressed once',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(AppButton(label: 'Go', onPressed: () => taps++)),
    );

    Focus.of(tester.element(find.text('Go'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(taps, 1);
  });
}
