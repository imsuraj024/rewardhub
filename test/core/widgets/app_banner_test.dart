import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/widgets/app_banner.dart';

import '../../helpers/harness.dart';

void main() {
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
}
