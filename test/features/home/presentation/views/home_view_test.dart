import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/points_balance_card.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/domain/usecases/get_recent_activities_usecase.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/home/presentation/views/home_view.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';
import 'package:rewardhub/features/wallet/presentation/controllers/wallet_controller.dart';

import '../../../../helpers/harness.dart';

class MockAuthController extends GetxController
    with Mock
    implements AuthController {}

class MockGetRecentActivitiesUseCase extends Mock
    implements GetRecentActivitiesUseCase {}

class MockProfileController extends GetxController
    with Mock
    implements ProfileController {}

class MockShellController extends GetxController
    with Mock
    implements ShellController {}

class MockWalletController extends GetxController
    with Mock
    implements WalletController {}

class MockAppAnalytics extends Mock implements AppAnalytics {}

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

/// Mirrors the header's hour ranges.
String _greeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17 && hour < 21) return 'Good evening';
  return 'Welcome back';
}

/// Local noon [daysAgo] days before today, so month ends and midnight can't
/// make the fixture flaky.
DateTime _daysAgo(int daysAgo) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - daysAgo, 12);
}

ViewStateSuccess<ProfileModel> _profile(
        {String name = 'John Doe', int points = 100}) =>
    ViewStateSuccess<ProfileModel>(
      ProfileModel(id: '1', name: name, mobile: '9876543210', points: points),
    );

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late MockAuthController authController;
  late MockGetRecentActivitiesUseCase getRecentActivities;
  late MockProfileController profileController;
  late MockShellController shellController;
  late MockWalletController walletController;
  late MockAppAnalytics analytics;
  late MockRemoteConfigService remoteConfig;
  late ViewState<ProfileModel> profileState;
  late List<RecentActivityModel> activities;
  late RxBool isSubmitting;

  setUp(() {
    installGetTestHarness();

    authController = MockAuthController();
    getRecentActivities = MockGetRecentActivitiesUseCase();
    profileController = MockProfileController();
    shellController = MockShellController();
    walletController = MockWalletController();
    analytics = MockAppAnalytics();
    remoteConfig = MockRemoteConfigService();
    profileState = _profile();
    activities = <RecentActivityModel>[];
    isSubmitting = false.obs;

    when(() => authController.token).thenReturn('test_token');
    when(() => authController.tokenListenable)
        .thenReturn(Rxn<String>('test_token'));
    when(() => getRecentActivities(any())).thenAnswer((_) async => activities);
    when(() => walletController.isSubmitting).thenAnswer((_) => isSubmitting);
    when(() => walletController.raiseRequest()).thenAnswer((_) async {});
    when(() => profileController.state).thenAnswer((_) => profileState);
    when(() => profileController.loadProfile(force: any(named: 'force')))
        .thenAnswer((_) async {});
    when(() => analytics.quickActionTapped(any())).thenAnswer((_) async {});
    when(() => remoteConfig.promotionalBanners).thenReturn([]);

    Get.put<ProfileController>(profileController);
    // Lazy, so each test's fixture is in place before the first load.
    Get.lazyPut<HomeController>(
      () => HomeController(
        authController: authController,
        getRecentActivities: getRecentActivities,
      ),
    );
    Get.put<ShellController>(shellController);
    Get.put<WalletController>(walletController);
    Get.put<AppAnalytics>(analytics);
    Get.put<RemoteConfigService>(remoteConfig);
  });

  tearDown(resetGet);

  void useSize(WidgetTester tester, double width, [double height = 640]) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpHome(WidgetTester tester, {double textScale = 1.0}) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: const HomeView(),
        ),
      ),
    );
  }

  Finder redeemTile() => find.ancestor(
        of: find.text('Redeem'),
        matching: find.byType(InkWell),
      );

  group('header', () {
    testWidgets('negative: profile error shows the bare greeting, no name',
        (tester) async {
      profileState = const ViewStateError<ProfileModel>('boom');

      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Suraj'), findsNothing);
      expect(find.text(_greeting()), findsOneWidget);
      expect(find.text('${_greeting()},'), findsNothing);
    });

    testWidgets('edge: profile loading shows the greeting and a skeleton',
        (tester) async {
      profileState = const ViewStateLoading<ProfileModel>();

      await pumpHome(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('${_greeting()},'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Shimmer),
          matching: find.byWidgetPredicate(
            (w) => w is SkeletonBox && w.width == 160 && w.height == 24,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('100'), findsNothing);
    });

    testWidgets('edge: a whitespace-only name counts as no name',
        (tester) async {
      profileState = _profile(name: '   ');

      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text(_greeting()), findsOneWidget);
      expect(find.text('${_greeting()},'), findsNothing);
    });

    testWidgets('positive: greeting and name are one heading, emoji silent',
        (tester) async {
      final semantics = tester.ensureSemantics();
      profileState = _profile(name: 'Ramesh Kumar');

      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Ramesh Kumar')),
        isSemantics(
          label: '${_greeting()},\nRamesh Kumar',
          isHeader: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('edge: a 40-character name ellipsizes at 320 dp and 2.0x',
        (tester) async {
      useSize(tester, 320);
      const longName = 'Venkata Subramanian Ramakrishnan Iyengar';
      profileState = _profile(name: longName);

      await pumpHome(tester, textScale: 2.0);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(longName),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
    });
  });

  group('balance card', () {
    testWidgets('negative: profile error shows retry, never a fake balance',
        (tester) async {
      profileState = const ViewStateError<ProfileModel>('boom');

      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
      expect(find.text("Couldn't load your points."), findsOneWidget);
      expect(find.textContaining('650'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      verify(() => profileController.loadProfile(force: true)).called(1);
    });

    testWidgets('edge: no activity → no chip and an honest footer',
        (tester) async {
      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('in 7 days'), findsNothing);
      expect(find.textContaining('this week'), findsNothing);
      expect(
        find.text('No points in the last 7 days. Scan a QR code to earn.'),
        findsOneWidget,
      );
    });

    testWidgets('negative: activities error explains the missing chart',
        (tester) async {
      when(() => getRecentActivities(any())).thenThrow(Exception('down'));

      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't load your recent points. Pull down to try again."),
        findsOneWidget,
      );
    });

    testWidgets('positive: the chip and the chart cover the same 7 days',
        (tester) async {
      activities = [
        RecentActivityModel(
            id: '1', type: 'credit', points: 50, date: _daysAgo(0)),
        RecentActivityModel(
            id: '2', type: 'credit', points: 100, date: _daysAgo(3)),
        RecentActivityModel(
            id: '3', type: 'debit', points: 1000, date: _daysAgo(0)),
        RecentActivityModel(
            id: '4', type: 'credit', points: 70, date: _daysAgo(8)),
      ];

      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('+150 in 7 days'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == '150 points earned in the last 7 days',
        ),
        findsOneWidget,
      );

      final bars = find.descendant(
        of: find.byType(PointsBalanceCard),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 14,
        ),
      );
      final heights = [
        for (final e in bars.evaluate())
          tester.getSize(find.byWidget(e.widget)).height,
      ];
      // Oldest → today: today−3 is the best day (100), today has 50.
      expect(heights, [4, 4, 4, 44, 4, 4, 22]);

      final labels = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(PointsBalanceCard),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(labels.last, DateFormat('E').format(DateTime.now()));
    });
  });

  group('redeem quick action', () {
    testWidgets('negative: disabled while the profile is unavailable',
        (tester) async {
      final semantics = tester.ensureSemantics();
      profileState = const ViewStateError<ProfileModel>('boom');

      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(tester.widget<InkWell>(redeemTile()).onTap, isNull);
      expect(
        tester.getSemantics(find.text('Redeem')),
        isSemantics(
          label: 'Redeem\nGet money for points',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('edge: zero points reads "No points yet" and is disabled',
        (tester) async {
      profileState = _profile(points: 0);

      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('No points yet'), findsOneWidget);
      expect(tester.widget<InkWell>(redeemTile()).onTap, isNull);
    });

    testWidgets('edge: while submitting, the badge spins and taps do nothing',
        (tester) async {
      isSubmitting.value = true;

      await pumpHome(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: redeemTile(),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(tester.widget<InkWell>(redeemTile()).onTap, isNull);
    });
  });

  group('how to earn points', () {
    // The user's override: every step number sits in a filled circle in the
    // step's colour.
    Finder numberBadges() => find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
              w.child is Text,
        );

    for (final scale in [1.0, 1.3]) {
      testWidgets('positive: three filled 18×18 number badges at ${scale}x',
          (tester) async {
        useSize(tester, 360, 2400);

        await pumpHome(tester, textScale: scale);
        await tester.pumpAndSettle();

        final badges = tester.widgetList<Container>(numberBadges()).toList();
        expect(
          badges.map((c) => (c.decoration! as BoxDecoration).color),
          [AppColors.success, AppColors.primary, AppColors.tertiaryStrong],
        );
        for (final badge in badges) {
          expect(tester.getSize(find.byWidget(badge)), const Size(18, 18));
          final digit = badge.child! as Text;
          expect(digit.style!.color, AppColors.onPrimary);
          expect(digit.style!.fontSize, 11);
          expect(digit.style!.fontWeight, FontWeight.w900);
        }
        expect(
          badges.map((c) => (c.child! as Text).data),
          ['1', '2', '3'],
        );
      });
    }

    testWidgets('edge: at 2.0x the steps stack and the badges grow',
        (tester) async {
      useSize(tester, 360, 2400);

      await pumpHome(tester, textScale: 2.0);
      await tester.pumpAndSettle();

      final badges = tester.widgetList<Container>(numberBadges()).toList();
      expect(badges, hasLength(3));
      for (final badge in badges) {
        expect(tester.getSize(find.byWidget(badge)), const Size(36, 36));
      }
    });
  });

  group('layout', () {
    for (final width in [320.0, 360.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('edge: no overflow at $width dp and ${scale}x',
            (tester) async {
          useSize(tester, width, 2400);
          activities = [
            RecentActivityModel(
              id: '1',
              type: 'credit',
              points: 123456,
              date: _daysAgo(1),
            ),
          ];

          await pumpHome(tester, textScale: scale);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('How to earn points'), findsOneWidget);
        });
      }
    }
  });
}
