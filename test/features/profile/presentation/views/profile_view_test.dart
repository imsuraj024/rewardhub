import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/profile/presentation/views/profile_view.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

class MockShorebirdUpdateService extends GetxService
    with Mock
    implements ShorebirdUpdateService {}

class MockAuthController extends GetxController
    with Mock
    implements AuthController {}

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

void main() {
  late AnalyticsHarness analyticsHarness;
  late MockRemoteConfigService mockRemoteConfig;
  late MockShorebirdUpdateService mockShorebird;
  late MockAuthController mockAuth;
  late MockGetProfileUseCase mockGetProfile;

  final testProfile = ProfileModel(
    id: 'user-1',
    name: 'Suraj Kumar',
    mobile: '9876543210',
    points: 450,
  );

  setUp(() {
    analyticsHarness = AnalyticsHarness();
    installGetTestHarness();
    mockRemoteConfig = MockRemoteConfigService();
    mockShorebird = MockShorebirdUpdateService();
    mockAuth = MockAuthController();
    mockGetProfile = MockGetProfileUseCase();

    when(() => mockAuth.token).thenReturn('token');
    when(() => mockAuth.tokenListenable).thenReturn(Rxn<String>('token'));
    when(() => mockGetProfile.call(any())).thenAnswer((_) async => testProfile);
    when(() => mockRemoteConfig.releaseNotes).thenReturn(
      '["Faster QR scan engine", "Direct UPI payout option"]',
    );
    when(() => mockShorebird.currentPatchNumber).thenReturn(null);

    Get.put<ProfileController>(
      ProfileController(
        authController: mockAuth,
        getProfile: mockGetProfile,
        analytics: analyticsHarness.analytics,
      ),
    );
    Get.put<RemoteConfigService>(mockRemoteConfig);
    Get.put<ShorebirdUpdateService>(mockShorebird);
    Get.put<AuthController>(mockAuth);
    Get.put(analyticsHarness.analytics);
  });

  tearDown(() async {
    await resetGet();
  });

  testWidgets(
      'renders What is New option in Account Settings and opens popup on click',
      (tester) async {
    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();

    expect(find.text('Suraj Kumar'), findsOneWidget);
    expect(find.text('Referral Code'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text("What's New"),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("What's New"), findsOneWidget);
    expect(find.text('Latest features and improvements'), findsOneWidget);

    // Click What's New to open the popup dialog
    await tester.tap(find.text("What's New").first);
    await tester.pumpAndSettle();

    // Verify popup contents
    expect(find.textContaining('Recent updates & improvements'), findsOneWidget);
    expect(find.text('Faster QR scan engine'), findsOneWidget);
    expect(find.text('Direct UPI payout option'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);

    // Dismiss popup
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Recent updates & improvements'), findsNothing);
  });

  testWidgets(
      'hides What is New row in Account Settings when releaseNotes is null or empty',
      (tester) async {
    when(() => mockRemoteConfig.releaseNotes).thenReturn(null);

    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();

    expect(find.text("What's New"), findsNothing);
  });

  testWidgets(
      'renders Invite Friends & Share section and opens referral bottom sheet',
      (tester) async {
    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();

    final finder = find.text('Invite Friends & Share');
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finder, findsOneWidget);

    // Tap Invite Friends & Share row
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify referral modal content
    expect(find.text('YOUR REFERRAL CODE'), findsOneWidget);
    expect(find.textContaining('KX-'), findsWidgets);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share Invite Link'), findsOneWidget);
  });

  testWidgets(
      'opens Logout bottom sheet and handles logout confirmation step flow',
      (tester) async {
    when(() => mockAuth.logout()).thenAnswer((_) async {});

    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();

    final logoutFinder = find.text('Logout Account');
    await tester.scrollUntilVisible(
      logoutFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();

    // Step 1: Confirm Logout
    expect(find.text('Log out?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    // Tap Log out button
    await tester.tap(find.text('Log out'));
    await tester.pump(); // Advance to logging out step

    expect(find.text('Logging out...'), findsOneWidget);

    // Complete delay for success state
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // Step 3: Success State
    expect(find.text('Logged out successfully'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Tap OK button
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    verify(() => mockAuth.logout()).called(1);
  });

  testWidgets(
      'renders Bank & Payment Details section when profile has upiId and bank details',
      (tester) async {
    final profileWithBank = ProfileModel(
      id: '10',
      name: 'Rohit',
      mobile: '9167360660',
      points: 8,
      bankName: 'HDFC Bank',
      bankAddress: 'Mumbai Branch',
      ifscCode: 'HDFC0001234',
      accountNumber: '987654321012',
      upiId: '8657221204@ybl',
    );
    when(() => mockGetProfile.call(any())).thenAnswer((_) async => profileWithBank);
    await Get.find<ProfileController>().loadProfile(force: true);

    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();

    final sectionFinder = find.text('Bank & Payment Details');
    await tester.scrollUntilVisible(
      sectionFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(find.text('Bank & Payment Details'), findsOneWidget);
    expect(find.text('8657221204@ybl'), findsOneWidget);
    expect(find.text('HDFC Bank'), findsOneWidget);
    expect(find.text('987654321012'), findsOneWidget);
    expect(find.text('HDFC0001234'), findsOneWidget);
    expect(find.text('Mumbai Branch'), findsOneWidget);
  });
}
