import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/domain/usecases/get_recent_activities_usecase.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';
import 'package:rewardhub/features/wallet/data/models/raise_request_response_model.dart';
import 'package:rewardhub/features/wallet/domain/usecases/raise_wallet_request_usecase.dart';
import 'package:rewardhub/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:rewardhub/features/wallet/presentation/views/wallet_view.dart';

import '../../../../helpers/harness.dart';

class MockAuthController extends GetxController
    with Mock
    implements AuthController {}

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockGetRecentActivitiesUseCase extends Mock
    implements GetRecentActivitiesUseCase {}

class MockRaiseWalletRequestUseCase extends Mock
    implements RaiseWalletRequestUseCase {}

class MockAppAnalytics extends Mock implements AppAnalytics {}

class MockShellController extends GetxController
    with Mock
    implements ShellController {}

void main() {
  late MockAuthController mockAuth;
  late MockGetProfileUseCase mockGetProfile;
  late MockGetRecentActivitiesUseCase mockGetActivities;
  late ProfileController profileController;
  late MockRaiseWalletRequestUseCase mockRaiseRequest;
  late MockAppAnalytics mockAnalytics;
  late WalletController walletController;
  late MockShellController mockShell;
  late List<RecentActivityModel> activities;

  ProfileModel profileWith(int points) => ProfileModel(
        id: '1',
        name: 'Test User',
        mobile: '9876543210',
        points: points,
      );

  RecentActivityModel credit(String id, int points) => RecentActivityModel(
        id: id,
        type: 'credit',
        points: points,
        date: DateTime(2026, 9, 1, 10),
      );

  setUp(() {
    installGetTestHarness();
    mockAuth = MockAuthController();
    mockGetProfile = MockGetProfileUseCase();
    mockGetActivities = MockGetRecentActivitiesUseCase();
    mockRaiseRequest = MockRaiseWalletRequestUseCase();
    mockAnalytics = MockAppAnalytics();
    mockShell = MockShellController();
    activities = <RecentActivityModel>[];

    when(() => mockAuth.token).thenReturn('token');
    when(() => mockAuth.tokenListenable).thenReturn(Rxn<String>('token'));
    when(() => mockGetProfile.call('token'))
        .thenAnswer((_) async => profileWith(650));
    when(() => mockGetActivities.call(any()))
        .thenAnswer((_) async => activities);
    // Without this the profile load fails and the card shows its error state.
    when(() => mockAnalytics.identify(any())).thenAnswer((_) async {});
    when(() => mockAnalytics.redeemRequested()).thenAnswer((_) async {});
    when(() => mockAnalytics.redeemSucceeded()).thenAnswer((_) async {});
    when(() => mockAnalytics.redeemFailed(any())).thenAnswer((_) async {});

    Get.put<AuthController>(mockAuth);

    Get.put<ShellController>(mockShell);
    // Lazy, so each test's activities fixture is in place before the load.
    Get.lazyPut<HomeController>(
      () => HomeController(
        authController: mockAuth,
        getRecentActivities: mockGetActivities,
      ),
    );

    walletController = WalletController(
      authController: mockAuth,
      raiseWalletRequest: mockRaiseRequest,
      analytics: mockAnalytics,
    );
    Get.put<WalletController>(walletController);
  });

  tearDown(() async {
    await resetGet();
  });

  // The profile loads on registration, so each test's stub must come first.
  Future<void> pumpWallet(WidgetTester tester) async {
    profileController = ProfileController(
      authController: mockAuth,
      getProfile: mockGetProfile,
      analytics: mockAnalytics,
    );
    Get.put<ProfileController>(profileController);
    await profileController.loadProfile();
    await pumpApp(tester, const WalletView());
    await tester.pumpAndSettle();
  }

  Finder redeemButton() => find.widgetWithText(AppButton, 'Redeem points');

  testWidgets('renders WalletView elements correctly', (tester) async {
    await pumpWallet(tester);

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Available points'), findsOneWidget);
    expect(find.text('650'), findsOneWidget);
    expect(find.text('points'), findsOneWidget);
    expect(find.text('Redeem points'), findsWidgets);
    expect(find.text('Transaction history'), findsOneWidget);
  });

  group('redeem', () {
    testWidgets('edge: zero points disables Redeem and explains why',
        (tester) async {
      when(() => mockGetProfile.call('token'))
          .thenAnswer((_) async => profileWith(0));

      await pumpWallet(tester);

      expect(tester.widget<AppButton>(redeemButton()).onPressed, isNull);
      expect(
        find.text(
          'You have no points to redeem yet. Scan a QR code to earn some.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('negative: profile error disables Redeem, no fake balance',
        (tester) async {
      when(() => mockGetProfile.call('token')).thenThrow(ApiException('down'));

      await pumpWallet(tester);

      expect(find.text('—'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('650'), findsNothing);
      expect(tester.widget<AppButton>(redeemButton()).onPressed, isNull);
    });

    testWidgets('negative: Cancel on the confirmation sends nothing',
        (tester) async {
      await pumpWallet(tester);

      await tester.tap(redeemButton());
      await tester.pumpAndSettle();

      expect(find.text('Redeem your points?'), findsOneWidget);
      expect(find.textContaining('You have 650 points.'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Redeem your points?'), findsNothing);
      verifyNever(() => mockRaiseRequest(any()));
    });

    testWidgets('positive: Send request calls the use case once',
        (tester) async {
      when(() => mockRaiseRequest(any())).thenAnswer(
        (_) async => const RaiseRequestResponseModel(success: true),
      );
      await pumpWallet(tester);

      await tester.tap(redeemButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();

      verify(() => mockRaiseRequest('token')).called(1);
    });
  });

  group('transaction history', () {
    testWidgets('edge: no transactions shows the empty state and Scan',
        (tester) async {
      await pumpWallet(tester);

      await tester.scrollUntilVisible(
        find.text('Scan QR code'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No transactions yet'), findsOneWidget);

      await tester.tap(find.text('Scan QR code'));
      await tester.pump();

      verify(() => mockShell.goToTab(ShellTab.qrScan.index)).called(1);
    });

    testWidgets('negative: a load error shows the message and retries',
        (tester) async {
      when(() => mockGetActivities.call(any()))
          .thenThrow(ApiException('Server is busy.'));

      await pumpWallet(tester);
      await tester.scrollUntilVisible(
        find.text('Try again'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text("Couldn't load your transactions"), findsOneWidget);
      expect(find.text('Server is busy.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      verify(() => mockGetActivities.call('token')).called(2);
    });

    testWidgets('positive: 7 items show 5 tiles and "View all (7)"',
        (tester) async {
      activities = [for (var i = 0; i < 7; i++) credit('$i', 10 + i)];

      await pumpWallet(tester);
      final viewAll = find.text('View all (7)');
      await tester.scrollUntilVisible(
        viewAll,
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Points earned'), findsNWidgets(5));
      expect(
        tester
            .getSize(find.ancestor(
              of: viewAll,
              matching: find.byType(TextButton),
            ))
            .height,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(viewAll);
      await tester.pumpAndSettle();

      expect(find.text('Transaction history'), findsNWidgets(2));
    });

    testWidgets('edge: 5 items show no "View all"', (tester) async {
      activities = [for (var i = 0; i < 5; i++) credit('$i', 10 + i)];

      await pumpWallet(tester);

      expect(find.textContaining('View all'), findsNothing);
    });

    testWidgets('positive: neutral labels, signed amounts, no status',
        (tester) async {
      activities = [
        credit('1', 200),
        RecentActivityModel(
          id: '2',
          type: 'debit',
          points: 1000,
          date: DateTime(2026, 9, 27, 15, 15),
        ),
      ];

      await pumpWallet(tester);
      await tester.scrollUntilVisible(
        find.text('Points redeemed'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Points earned'), findsOneWidget);
      expect(find.text('+200 points'), findsOneWidget);
      expect(find.text('−1,000 points'), findsOneWidget);
      expect(find.text('27 Sep, 3:15 PM'), findsOneWidget);
      expect(find.text('Success'), findsNothing);
      expect(find.text('Referral Bonus'), findsNothing);
    });
  });
}
