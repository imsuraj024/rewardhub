import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/widgets/app_banner.dart';

import '../../helpers/harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(installGetTestHarness);
  tearDown(resetGet);

  group('AppBanner.image', () {
    testWidgets('renders image banner with text overlays and badge',
        (tester) async {
      await pumpApp(
        tester,
        AppBanner.image(
          imageUrl: 'assets/images/banner.png',
          isNetwork: false,
          title: 'Special Summer Offer',
          subtitle: 'Get 2X rewards on all fittings',
          badgeText: 'FESTIVE',
        ),
      );
      await tester.pump();

      expect(find.text('Special Summer Offer'), findsOneWidget);
      expect(find.text('Get 2X rewards on all fittings'), findsOneWidget);
      expect(find.text('FESTIVE'), findsOneWidget);
    });
  });

  group('AppBanner.text', () {
    testWidgets('renders text banner with style, icon, and badge',
        (tester) async {
      await pumpApp(
        tester,
        AppBanner.text(
          title: 'Referral Rewards',
          subtitle: 'Earn 50 pts for every friend who joins',
          badgeText: 'LIMITED OFFER',
          icon: Icons.card_giftcard_rounded,
          style: AppBannerStyle.primary,
        ),
      );
      await tester.pump();

      expect(find.text('Referral Rewards'), findsOneWidget);
      expect(
        find.text('Earn 50 pts for every friend who joins'),
        findsOneWidget,
      );
      expect(find.text('LIMITED OFFER'), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
    });

    testWidgets('supports different AppBannerStyle presets', (tester) async {
      for (final style in AppBannerStyle.values) {
        await pumpApp(
          tester,
          AppBanner.text(
            title: 'Style Test',
            subtitle: 'Testing style preset',
            style: style,
          ),
        );
        await tester.pump();
        expect(find.text('Style Test'), findsOneWidget);
      }
    });
  });

  group('AppBanner.split', () {
    testWidgets('renders split banner with text and graphic widget',
        (tester) async {
      await pumpApp(
        tester,
        AppBanner.split(
          title: 'Double Points Weekend',
          subtitle: 'Earn double on all scans',
          badgeText: 'NEW ARRIVAL',
          style: AppBannerStyle.gold,
          graphic: const Icon(Icons.star_rounded, key: Key('graphic_star')),
        ),
      );
      await tester.pump();

      expect(find.text('Double Points Weekend'), findsOneWidget);
      expect(find.text('Earn double on all scans'), findsOneWidget);
      expect(find.text('NEW ARRIVAL'), findsOneWidget);
      expect(find.byKey(const Key('graphic_star')), findsOneWidget);
    });
  });

  group('AppBannerCarousel', () {
    testWidgets('renders carousel with multiple slides and dot indicators',
        (tester) async {
      await pumpApp(
        tester,
        AppBannerCarousel(
          height: 160,
          autoPlay: false,
          banners: [
            AppBanner.text(title: 'Slide 1', subtitle: 'First banner'),
            AppBanner.text(title: 'Slide 2', subtitle: 'Second banner'),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Slide 1'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('handles single banner gracefully without carousel wrapper',
        (tester) async {
      await pumpApp(
        tester,
        AppBannerCarousel(
          autoPlay: false,
          banners: [
            AppBanner.text(title: 'Single Banner', subtitle: 'Only one item'),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Single Banner'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });
  });

  group('AppBannerCarousel behaviour', () {
    List<Widget> slides() => [
          AppBanner.text(title: 'Slide 1', subtitle: 'First banner'),
          AppBanner.text(title: 'Slide 2', subtitle: 'Second banner'),
          AppBanner.text(title: 'Slide 3', subtitle: 'Third banner'),
        ];

    Widget carousel({MediaQueryData? media, List<Widget>? banners}) {
      final child = AppBannerCarousel(banners: banners ?? slides());
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MediaQuery(
              data: media ?? MediaQuery.of(context),
              child: child,
            ),
          ),
        ),
      );
    }

    // Disposes the carousel so its periodic timer doesn't outlive the test.
    Future<void> unmount(WidgetTester tester) =>
        tester.pumpWidget(const SizedBox.shrink());

    testWidgets('positive: auto-plays to the next banner', (tester) async {
      await tester.pumpWidget(carousel());
      expect(find.text('Slide 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Slide 2'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('edge: a finger on the carousel pauses it until release',
        (tester) async {
      await tester.pumpWidget(carousel());

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('Slide 1'), findsOneWidget);
      expect(find.text('Slide 2'), findsNothing);

      await gesture.up();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Slide 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Slide 2'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('edge: reduced motion turns auto-play off', (tester) async {
      await tester.pumpWidget(
        carousel(media: const MediaQueryData(disableAnimations: true)),
      );

      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Slide 1'), findsOneWidget);
      expect(find.text('Slide 2'), findsNothing);

      await unmount(tester);
    });

    testWidgets('edge: a screen reader turns auto-play off', (tester) async {
      await tester.pumpWidget(
        carousel(media: const MediaQueryData(accessibleNavigation: true)),
      );

      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Slide 1'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('positive: each banner announces its position; dots are '
        'hidden', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        carousel(media: const MediaQueryData(disableAnimations: true)),
      );

      expect(
        find.bySemanticsLabel(RegExp(r'^Banner 1 of 3')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Slide 1')), findsOneWidget);
      final dots = find.ancestor(
        of: find.byType(AnimatedContainer).first,
        matching: find.byType(ExcludeSemantics),
      );
      expect(dots, findsWidgets);

      handle.dispose();
      await unmount(tester);
    });

    testWidgets('positive: inactive dots use the outline colour',
        (tester) async {
      await tester.pumpWidget(
        carousel(media: const MediaQueryData(disableAnimations: true)),
      );

      final dots = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      expect(dots, [AppColors.primary, AppColors.outline, AppColors.outline]);

      await unmount(tester);
    });

    testWidgets('edge: height grows with text size, capped at 1.5x',
        (tester) async {
      await tester.pumpWidget(
        carousel(
          media: const MediaQueryData(
            disableAnimations: true,
            textScaler: TextScaler.linear(2.0),
          ),
          banners: [
            AppBanner.split(
              title: 'Double points',
              subtitle: 'Earn double on every scan this weekend only',
              graphic: const Icon(Icons.star_rounded),
            ),
            AppBanner.split(
              title: 'Refer a friend',
              subtitle: 'Share your code with another contractor',
              graphic: const Icon(Icons.star_rounded),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(PageView)).height, 225);

      await unmount(tester);
    });
  });

  group('banner tokens and semantics', () {
    testWidgets('positive: an image banner with no copy reads as "Promotion"',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        AppBanner.image(imageUrl: 'assets/images/banner.png', isNetwork: false),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Promotion'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('positive: image banner copy is full-strength onPrimary',
        (tester) async {
      await pumpApp(
        tester,
        AppBanner.image(
          imageUrl: 'assets/images/banner.png',
          isNetwork: false,
          title: 'Offer',
          subtitle: 'Details',
          badgeText: 'new',
        ),
      );
      await tester.pump();

      expect(
        tester.widget<Text>(find.text('Offer')).style?.color,
        AppColors.onPrimary,
      );
      expect(
        tester.widget<Text>(find.text('Details')).style?.color,
        AppColors.onPrimary,
      );
      final badge = tester.widget<Text>(find.text('NEW'));
      expect(badge.style?.color, AppColors.onPrimary);
      expect(badge.style?.fontSize, 11);
      expect(find.bySemanticsLabel('Promotion'), findsNothing);
    });

    testWidgets('positive: the gold preset uses the gold tokens',
        (tester) async {
      await pumpApp(
        tester,
        AppBanner.text(
          title: 'Gold',
          subtitle: 'Warm',
          badgeText: 'tier',
          style: AppBannerStyle.gold,
        ),
      );
      await tester.pump();

      expect(
        tester.widget<Text>(find.text('Gold')).style?.color,
        AppColors.onTertiaryFixed,
      );
      expect(
        tester.widget<Text>(find.text('Warm')).style?.color,
        AppColors.tertiaryStrong,
      );
      expect(
        tester.widget<Text>(find.text('TIER')).style?.color,
        AppColors.onPrimary,
      );
    });
  });
}
