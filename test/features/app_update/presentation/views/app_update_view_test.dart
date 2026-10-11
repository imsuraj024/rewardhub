import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/external_links.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/app_update/presentation/views/app_update_view.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../helpers/harness.dart';

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

class MockAuthController extends GetxController
    with Mock
    implements AuthController {}

void main() {
  late MockRemoteConfigService mockRemoteConfig;
  late MockAuthController mockAuth;
  late List<RecordedToast> toasts;
  late List<String> clipboard;

  setUp(() {
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
    mockAuth = MockAuthController();

    when(() => mockRemoteConfig.releaseNotes).thenReturn(
      '["Super fast scan engine", "Instant UPI settlements"]',
    );
    when(() => mockAuth.isAuthenticated).thenReturn(false);

    Get.put<RemoteConfigService>(mockRemoteConfig);
    Get.put<AuthController>(mockAuth);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    ExternalLinks.opener = null;
    await resetGet();
  });

  testWidgets(
      'renders AppUpdateView with JSON release notes array and store buttons',
      (tester) async {
    await pumpApp(tester, const AppUpdateView());
    await tester.pump();

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Super fast scan engine'), findsOneWidget);
    expect(find.text('Instant UPI settlements'), findsOneWidget);
    expect(find.textContaining('Update on'), findsOneWidget);
  });

  testWidgets('renders AppUpdateView with JSON object format {"notes": [...]}',
      (tester) async {
    when(() => mockRemoteConfig.releaseNotes).thenReturn(
      '{"notes": ["Quick login", "Dark mode enhancements"]}',
    );

    await pumpApp(tester, const AppUpdateView());
    await tester.pump();

    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Quick login'), findsOneWidget);
    expect(find.text('Dark mode enhancements'), findsOneWidget);
  });

  testWidgets(
      'hides What is New section completely when releaseNotes is empty or null',
      (tester) async {
    when(() => mockRemoteConfig.releaseNotes).thenReturn(null);

    await pumpApp(tester, const AppUpdateView());
    await tester.pump();

    expect(find.text("What's new"), findsNothing);
    expect(find.text('Update required'), findsOneWidget);
  });

  testWidgets(
      'hides What is New section when releaseNotes is empty JSON array []',
      (tester) async {
    when(() => mockRemoteConfig.releaseNotes).thenReturn('[]');

    await pumpApp(tester, const AppUpdateView());
    await tester.pump();

    expect(find.text("What's new"), findsNothing);
    expect(find.text('Update required'), findsOneWidget);
  });

  testWidgets('says the update is required, without "enjoy" or VERSION',
      (tester) async {
    await pumpApp(tester, const AppUpdateView());
    await tester.pump();

    expect(
      find.text(
        'This version of Kitox Hardware no longer works. Update the app to '
        'keep scanning and redeeming points.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('enjoy'), findsNothing);
    expect(find.textContaining('VERSION'), findsNothing);
    expect(find.text('Kitox Hardware'), findsOneWidget);
  });

  group('opening the store', () {
    testWidgets('failure: error toast, then "Copy store link" copies the URL',
        (tester) async {
      final modes = <LaunchMode>[];
      ExternalLinks.opener = (_, mode) async {
        modes.add(mode);
        return false;
      };

      await pumpApp(tester, const AppUpdateView());
      await tester.pump();
      expect(find.text('Copy store link'), findsNothing);

      await tester.tap(find.text('Update on Play Store'));
      await tester.pump();

      expect(
          modes, [LaunchMode.externalApplication, LaunchMode.platformDefault]);
      expect(toasts.single.type, ToastType.error);
      expect(
        toasts.single.message,
        "Couldn't open the Play Store. Copy the link below and open it in "
        'your browser.',
      );
      expect(find.text('Copy store link'), findsOneWidget);

      await tester.tap(find.text('Copy store link'));
      await tester.pump();

      expect(clipboard, [
        'https://play.google.com/store/apps/details?id=com.loyalty.rewardhub',
      ]);
      expect(toasts.last.type, ToastType.success);
      expect(toasts.last.message, 'Link copied. Paste it in your browser.');
    });

    testWidgets('success: no toast and no copy button', (tester) async {
      var calls = 0;
      ExternalLinks.opener = (_, __) async {
        calls++;
        return true;
      };

      await pumpApp(tester, const AppUpdateView());
      await tester.pump();

      await tester.tap(find.text('Update on Play Store'));
      await tester.pump();

      expect(calls, 1);
      expect(toasts, isEmpty);
      expect(find.text('Copy store link'), findsNothing);
    });

    testWidgets('a second tap while opening does nothing', (tester) async {
      final gate = Completer<bool>();
      var calls = 0;
      ExternalLinks.opener = (_, __) {
        calls++;
        return gate.future;
      };

      await pumpApp(tester, const AppUpdateView());
      await tester.pump();

      await tester.tap(find.text('Update on Play Store'));
      await tester.pump();
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, 'Update on Play Store'),
            )
            .isLoading,
        isTrue,
      );
      await tester.tap(find.text('Update on Play Store'));
      await tester.pump();
      expect(calls, 1);

      gate.complete(true);
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('back stays blocked', (tester) async {
      await pumpApp(tester, const AppUpdateView());
      await tester.pump();

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });
  });

  // The test font's glyphs are full-em squares (about twice Inter's width),
  // so 1.3x here is wider than 2.0x Inter on a device.
  Future<void> pumpSmall(
    WidgetTester tester,
    Widget child, {
    double textScale = 2.0,
  }) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('8 release notes fit 320x568 at large text', (tester) async {
    when(() => mockRemoteConfig.releaseNotes).thenReturn(
      '["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"]',
    );
    await pumpSmall(tester, const AppUpdateView(), textScale: 1.3);
    expect(tester.takeException(), isNull);
  });
}
