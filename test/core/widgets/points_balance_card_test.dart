import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/points_balance_card.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const graphicKey = Key('coins');

  void useWidth(WidgetTester tester, double width) {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  // The card sits inside the 16 dp page gutter on Home and Wallet.
  Widget wrap(Widget card, {double textScale = 1.0}) => MaterialApp(
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: app!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: card,
          ),
        ),
      );

  Widget badge() => Container(
        width: 131,
        height: 24,
        color: Colors.white24,
      );

  group('layout', () {
    for (final width in [320.0, 360.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        for (final points in [0, 100000, 12345678]) {
          for (final withBadge in [false, true]) {
            testWidgets(
                'edge: no overflow at $width dp, ${scale}x, $points points, '
                'badge: $withBadge', (tester) async {
              useWidth(tester, width);
              await tester.pumpWidget(
                wrap(
                  PointsBalanceCard(
                    label: 'Your points',
                    points: points,
                    badge: withBadge ? badge() : null,
                    graphic: const Icon(Icons.savings_rounded, key: graphicKey),
                  ),
                  textScale: scale,
                ),
              );

              expect(tester.takeException(), isNull);
            });
          }
        }
      }
    }

    testWidgets('edge: the graphic hides at 320 dp and shows at 360 dp',
        (tester) async {
      Widget card() => wrap(
            const PointsBalanceCard(
              label: 'Your points',
              points: 1500,
              graphic: Icon(Icons.savings_rounded, key: graphicKey),
            ),
          );

      useWidth(tester, 320);
      await tester.pumpWidget(card());
      expect(find.byKey(graphicKey), findsNothing);

      useWidth(tester, 360);
      await tester.pumpWidget(card());
      expect(find.byKey(graphicKey), findsOneWidget);

      final numberRight = tester.getTopRight(find.text('1,500')).dx;
      final graphicLeft = tester.getTopLeft(find.byKey(graphicKey)).dx;
      expect(numberRight, lessThanOrEqualTo(graphicLeft));
    });
  });

  testWidgets('positive: value state shows grouped points and the unit',
      (tester) async {
    await tester.pumpWidget(
      wrap(const PointsBalanceCard(label: 'Your points', points: 100000)),
    );

    expect(find.text('1,00,000'), findsOneWidget);
    expect(find.text('points'), findsOneWidget);
    expect(find.byType(SkeletonBox), findsNothing);
  });

  testWidgets('edge: one point reads "1 point"', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(const PointsBalanceCard(label: 'Your points', points: 1)),
    );

    expect(find.text('point'), findsOneWidget);
    expect(find.bySemanticsLabel('Your points, 1 point'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('positive: a refresh with a stale value keeps the number',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const PointsBalanceCard(
          label: 'Your points',
          points: 250,
          isLoading: true,
        ),
      ),
    );

    expect(find.text('250'), findsOneWidget);
    expect(find.byType(SkeletonBox), findsNothing);
  });

  testWidgets('positive: loading with no value shows one dark skeleton',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const PointsBalanceCard(
          label: 'Your points',
          points: null,
          isLoading: true,
        ),
      ),
    );

    final box = tester.widget<SkeletonBox>(find.byType(SkeletonBox));
    expect(box.onDark, isTrue);
    expect(tester.widget<Shimmer>(find.byType(Shimmer)).onDark, isTrue);
    expect(find.text('—'), findsNothing);
    expect(find.text('points'), findsNothing);
  });

  testWidgets('negative: error state shows a dash, the message and Try again',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      wrap(
        PointsBalanceCard(
          label: 'Your points',
          points: null,
          onRetry: () => retries++,
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text("Couldn't load your points."), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('edge: error state without onRetry has no button and uses the '
      'given message', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        const PointsBalanceCard(
          label: 'Available points',
          points: null,
          errorMessage: "You're offline.",
        ),
      ),
    );

    expect(find.text("You're offline."), findsOneWidget);
    expect(find.byType(AppButton), findsNothing);
    expect(
      find.bySemanticsLabel('Available points, not available'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('positive: a footer renders under the value', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PointsBalanceCard(
          label: 'Your points',
          points: 10,
          footer: Text('weekly chart'),
        ),
      ),
    );

    expect(find.text('weekly chart'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('weekly chart')).dy,
      greaterThan(tester.getBottomLeft(find.text('10')).dy),
    );
  });
}
