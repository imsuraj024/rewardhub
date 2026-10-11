import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/widgets/app_bottom_sheet.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
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
  late List<RecordedToast> toasts;
  late List<String> clipboard;

  final testProfile = ProfileModel(
    id: 'user-1',
    name: 'Suraj Kumar',
    mobile: '9876543210',
    points: 450,
  );

  ProfileController putProfileController() => Get.put<ProfileController>(
        ProfileController(
          authController: mockAuth,
          getProfile: mockGetProfile,
          analytics: analyticsHarness.analytics,
        ),
      );

  setUp(() {
    analyticsHarness = AnalyticsHarness();
    toasts = installGetTestHarness();
    clipboard = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    mockRemoteConfig = MockRemoteConfigService();
    mockShorebird = MockShorebirdUpdateService();
    mockAuth = MockAuthController();
    mockGetProfile = MockGetProfileUseCase();

    when(() => mockAuth.token).thenReturn('token');
    when(() => mockAuth.tokenListenable).thenReturn(Rxn<String>('token'));
    when(() => mockAuth.errorMessage).thenReturn(null);
    when(() => mockGetProfile.call(any())).thenAnswer((_) async => testProfile);
    when(() => mockRemoteConfig.releaseNotes).thenReturn(
      '["Faster QR scan engine", "Direct UPI payout option"]',
    );
    when(() => mockShorebird.currentPatchNumber).thenReturn(null);

    putProfileController();
    Get.put<RemoteConfigService>(mockRemoteConfig);
    Get.put<ShorebirdUpdateService>(mockShorebird);
    Get.put<AuthController>(mockAuth);
    Get.put(analyticsHarness.analytics);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await resetGet();
  });

  Finder inSheet(Finder matching) =>
      find.descendant(of: find.byType(AppBottomSheet), matching: matching);

  AppButton sheetButton(WidgetTester tester, String label) =>
      tester.widget<AppButton>(inSheet(find.widgetWithText(AppButton, label)));

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'renders What is New option in Account Settings and opens popup on click',
      (tester) async {
    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();

    expect(find.text('Suraj Kumar'), findsOneWidget);
    expect(find.text('Referral code'), findsOneWidget);

    await scrollTo(tester, find.text("What's new"));
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Latest features and improvements'), findsOneWidget);

    // Click What's new to open the sheet
    await tester.tap(find.text("What's new").first);
    await tester.pumpAndSettle();

    // Row title plus sheet title
    expect(find.text("What's new"), findsNWidgets(2));
    // PackageInfo has no platform in tests: no version line, no fallback.
    // The resolved version is covered in profile_version_test.dart.
    expect(find.textContaining('Version'), findsNothing);
    expect(find.textContaining('1.1.0'), findsNothing);
    expect(find.text('Faster QR scan engine'), findsOneWidget);
    expect(find.text('Direct UPI payout option'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
    expect(find.textContaining('Recent updates'), findsNothing);

    // Dismiss the sheet
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsOneWidget);
  });

  testWidgets('What is new splits "title: details" notes and shows no default',
      (tester) async {
    when(() => mockRemoteConfig.releaseNotes).thenReturn(
      '["Faster scan: Scan in half the time", "Bug fixes"]',
    );

    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text("What's new"));
    await tester.tap(find.text("What's new"));
    await tester.pumpAndSettle();

    expect(find.text('Faster scan'), findsOneWidget);
    expect(find.text('Scan in half the time'), findsOneWidget);
    expect(find.text('Bug fixes'), findsOneWidget);
    expect(
      find.text('Latest updates & performance improvements.'),
      findsNothing,
    );
  });

  testWidgets(
      'hides What is New row in Account Settings when releaseNotes is null or empty',
      (tester) async {
    when(() => mockRemoteConfig.releaseNotes).thenReturn(null);

    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsNothing);
  });

  testWidgets('renders Invite friends row and opens referral bottom sheet',
      (tester) async {
    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();

    final finder = find.text('Invite friends');
    await scrollTo(tester, finder);
    expect(finder, findsOneWidget);

    // Tap the Invite friends row
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify referral sheet content
    expect(find.text('Invite friends'), findsNWidgets(2));
    expect(find.text('Your referral code'), findsOneWidget);
    expect(find.textContaining('KX-'), findsWidgets);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Copy invite message'), findsOneWidget);
    expect(find.text('Share Invite Link'), findsNothing);
  });

  testWidgets('Copy invite message copies the invite and shows a plain toast',
      (tester) async {
    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Invite friends'));
    await tester.tap(find.text('Invite friends'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copy invite message'));
    await tester.pumpAndSettle();

    expect(clipboard.single, contains('Use my referral code: KX-'));
    expect(toasts.single.type, ToastType.success);
    expect(
      toasts.single.message,
      'Invite copied. Paste it in WhatsApp or SMS.',
    );
    expect(toasts.single.title, isNull);

    await tester.tap(find.widgetWithText(AppButton, 'Copy'));
    await tester.pumpAndSettle();

    expect(clipboard.last, startsWith('KX-'));
    expect(toasts.last.message, 'Referral code copied.');
    expect(toasts.last.title, isNull);
  });

  group('log out', () {
    testWidgets('confirming really logs out, once, with no success step',
        (tester) async {
      when(() => mockAuth.logout()).thenAnswer((_) async {});

      await pumpApp(tester, const ProfileView());
      await tester.pumpAndSettle();

      final logoutButton = find.widgetWithText(AppButton, 'Log out');
      expect(logoutButton, findsOneWidget);
      expect(find.text('Logout Account'), findsNothing);

      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      expect(
        find.text("You'll need your mobile number to log in again."),
        findsOneWidget,
      );
      expect(inSheet(find.text('Cancel')), findsOneWidget);

      await tester.tap(inSheet(find.text('Log out')));
      await tester.pumpAndSettle();

      verify(() => mockAuth.logout()).called(1);
      expect(find.text('Logging out...'), findsNothing);
      expect(find.text('Logged out successfully'), findsNothing);
    });

    testWidgets('Cancel keeps the user logged in', (tester) async {
      when(() => mockAuth.logout()).thenAnswer((_) async {});

      await pumpApp(tester, const ProfileView());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Log out'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsNothing);
      verifyNever(() => mockAuth.logout());
    });

    testWidgets('a failing logout shows an error toast', (tester) async {
      when(() => mockAuth.logout()).thenThrow(Exception('storage'));

      await pumpApp(tester, const ProfileView());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Log out'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Log out')));
      await tester.pumpAndSettle();

      expect(toasts.single.type, ToastType.error);
      expect(toasts.single.message, "Couldn't log you out. Please try again.");
    });
  });

  testWidgets(
      'renders Payment details section when profile has upiId and bank details',
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
    when(() => mockGetProfile.call(any()))
        .thenAnswer((_) async => profileWithBank);
    await Get.find<ProfileController>().loadProfile(force: true);
    final semantics = tester.ensureSemantics();

    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();

    final sectionFinder = find.text('Payment details');
    await tester.scrollUntilVisible(
      sectionFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(find.text('Payment details'), findsOneWidget);
    expect(find.text('8657221204@ybl'), findsOneWidget);
    expect(find.text('HDFC Bank'), findsOneWidget);
    expect(find.text('•••• 1012'), findsOneWidget);
    expect(find.text('987654321012'), findsNothing);
    expect(find.text('HDFC0001234'), findsOneWidget);
    expect(find.text('Mumbai Branch'), findsOneWidget);
    expect(
      find.semantics.byLabel('Account number, ending in 1012'),
      findsOne,
    );
    expect(find.semantics.byLabel(RegExp('••••')), findsNothing);
    expect(find.text('To change these, email support.'), findsOneWidget);
    expect(find.text('Not Provided'), findsNothing);
    semantics.dispose();
  });

  testWidgets('a 4-character account number is shown unmasked', (tester) async {
    when(() => mockGetProfile.call(any())).thenAnswer(
      (_) async => ProfileModel(
        id: '10',
        name: 'Rohit',
        mobile: '9167360660',
        points: 8,
        accountNumber: '1234',
      ),
    );
    await Get.find<ProfileController>().loadProfile(force: true);

    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('1234'));

    expect(find.text('1234'), findsOneWidget);
    expect(find.text('Not added'), findsOneWidget); // UPI
  });

  group('profile load error', () {
    testWidgets('shows the error card with Try again, which reloads',
        (tester) async {
      await Get.delete<ProfileController>(force: true);
      when(() => mockGetProfile.call(any())).thenThrow(Exception('offline'));
      putProfileController();

      await pumpApp(tester, const ProfileView());
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load your profile"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('User'), findsNothing);
      expect(find.text('?'), findsNothing);
      expect(find.text('Referral code'), findsNothing);
      // The rest of the page stays usable.
      expect(find.widgetWithText(AppButton, 'Log out'), findsOneWidget);
      await scrollTo(tester, find.text('Account settings'));
      expect(find.text('Account settings'), findsOneWidget);

      clearInteractions(mockGetProfile);
      when(() => mockGetProfile.call(any()))
          .thenAnswer((_) async => testProfile);

      await scrollTo(tester, find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      verify(() => mockGetProfile.call(any())).called(1);
      expect(
        find.text("Couldn't load your profile", skipOffstage: false),
        findsNothing,
      );
      expect(find.text('Referral code', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Payment details', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('pull to refresh reloads with force and keeps the data',
        (tester) async {
      await pumpApp(tester, const ProfileView());
      await tester.pumpAndSettle();
      clearInteractions(mockGetProfile);

      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      expect(find.text('Suraj Kumar'), findsOneWidget);
      await tester.pumpAndSettle();

      verify(() => mockGetProfile.call(any())).called(1);
      expect(find.text('Suraj Kumar'), findsOneWidget);
    });
  });

  group('delete account', () {
    Future<void> openDeleteSheet(WidgetTester tester) async {
      await pumpApp(
        tester,
        const ProfileView(),
        routes: [
          GetPage(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('login-stub')),
          ),
        ],
      );
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Delete account'));
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
    }

    Future<void> confirmIntent(WidgetTester tester) async {
      final checkbox = inSheet(find.byType(Checkbox));
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();
      final field = inSheet(find.byType(TextField));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'DELETE MY ACCOUNT');
      await tester.pump();
    }

    testWidgets('the row opens the sheet', (tester) async {
      await openDeleteSheet(tester);

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(inSheet(find.text('Delete account')), findsNWidgets(2));
      expect(find.text("This can't be undone."), findsOneWidget);
      expect(find.text('If you delete your account:'), findsOneWidget);
      expect(find.text('Type DELETE MY ACCOUNT to confirm'), findsOneWidget);
    });

    testWidgets('Delete stays disabled until the tick and the phrase',
        (tester) async {
      await openDeleteSheet(tester);

      expect(sheetButton(tester, 'Delete account').onPressed, isNull);

      final checkbox = inSheet(find.byType(Checkbox));
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();
      expect(sheetButton(tester, 'Delete account').onPressed, isNull);

      final field = inSheet(find.byType(TextField));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'DELETE MY');
      await tester.pump();
      expect(sheetButton(tester, 'Delete account').onPressed, isNull);

      await tester.enterText(field, 'DELETE MY ACCOUNT');
      await tester.pump();
      expect(sheetButton(tester, 'Delete account').onPressed, isNotNull);
    });

    testWidgets('success goes to Login and shows a plain toast',
        (tester) async {
      when(() => mockAuth.deleteAccount()).thenAnswer((_) async => true);
      await openDeleteSheet(tester);
      await confirmIntent(tester);

      final delete = inSheet(find.widgetWithText(AppButton, 'Delete account'));
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();

      verify(() => mockAuth.deleteAccount()).called(1);
      verifyNever(() => mockAuth.logout());
      expect(find.text('login-stub'), findsOneWidget);
      expect(find.byType(ProfileView), findsNothing);
      expect(find.byType(AppBottomSheet), findsNothing);
      expect(toasts.single.type, ToastType.success);
      expect(toasts.single.message, 'Your account is deleted.');
      expect(toasts.single.title, isNull);
    });

    testWidgets('failure shows the fallback message inline and stays open',
        (tester) async {
      when(() => mockAuth.deleteAccount()).thenAnswer((_) async => false);
      await openDeleteSheet(tester);
      await confirmIntent(tester);

      final delete = inSheet(find.widgetWithText(AppButton, 'Delete account'));
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Couldn't delete your account. Check your internet and try again.",
        ),
        findsOneWidget,
      );
      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(sheetButton(tester, 'Cancel').onPressed, isNotNull);
      expect(toasts, isEmpty);
    });

    testWidgets('while deleting, Cancel is disabled and back keeps it open',
        (tester) async {
      final pending = Completer<bool>();
      when(() => mockAuth.deleteAccount()).thenAnswer((_) => pending.future);
      await openDeleteSheet(tester);
      await confirmIntent(tester);

      final delete = inSheet(find.widgetWithText(AppButton, 'Delete account'));
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pump();

      expect(sheetButton(tester, 'Delete account').isLoading, isTrue);
      expect(sheetButton(tester, 'Cancel').onPressed, isNull);

      // The spinner never settles, so pump fixed frames.
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AppBottomSheet), findsOneWidget);

      pending.complete(false);
      await tester.pumpAndSettle();
      expect(sheetButton(tester, 'Cancel').onPressed, isNotNull);
    });
  });

  testWidgets('no overflow at 320 dp with 2.0x text and a long name',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    when(() => mockGetProfile.call(any())).thenAnswer(
      (_) async => ProfileModel(
        id: 'user-1',
        name: 'A' * 60,
        mobile: '9876543210',
        points: 1,
        bankAddress: 'B' * 60,
        bankName: 'HDFC Bank',
      ),
    );
    await Get.find<ProfileController>().loadProfile(force: true);

    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2.0),
          ),
          child: const ProfileView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final name = tester.widget<Text>(find.text('A' * 60));
    expect(name.maxLines, 2);
    expect(name.textAlign, TextAlign.center);
  });
}
