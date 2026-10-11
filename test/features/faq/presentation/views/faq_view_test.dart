import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/external_links.dart';
import 'package:rewardhub/features/faq/presentation/views/faq_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

void main() {
  late MockRemoteConfigService mockRemoteConfig;
  late AnalyticsHarness analyticsHarness;
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
    analyticsHarness = AnalyticsHarness();

    when(() => mockRemoteConfig.supportEmail)
        .thenReturn('custom_support@example.com');

    Get.put<RemoteConfigService>(mockRemoteConfig);
    Get.put<AppAnalytics>(analyticsHarness.analytics);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    ExternalLinks.opener = null;
    await resetGet();
  });

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  bool isSelected(WidgetTester tester, String label) => tester
      .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
      .selected;

  testWidgets('renders FaqView with support email from RemoteConfigService',
      (tester) async {
    await pumpApp(tester, const FaqView());
    await tester.pump();

    expect(find.text('Help & support'), findsOneWidget);
    expect(find.text('custom_support@example.com'), findsOneWidget);
  });

  testWidgets(
      'falls back to default kSupportEmail when RemoteConfigService is not registered',
      (tester) async {
    await resetGet();
    installGetTestHarness();

    await pumpApp(tester, const FaqView());
    await tester.pump();

    expect(find.text('support@kitoxhardware.com'), findsOneWidget);
  });

  group('scope and search', () {
    testWidgets('"All" is selected by default and lists every category',
        (tester) async {
      useTallScreen(tester);
      await pumpApp(tester, const FaqView());
      await tester.pump();

      expect(isSelected(tester, 'All'), isTrue);
      expect(isSelected(tester, 'Earning points'), isFalse);
      // Chip plus header for each category.
      expect(find.text('Getting started'), findsNWidgets(2));
      expect(find.text('Account & security', skipOffstage: false),
          findsNWidgets(2));
    });

    testWidgets('searching from a category spans every category',
        (tester) async {
      useTallScreen(tester);
      await pumpApp(tester, const FaqView());
      await tester.pump();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Earning points'));
      await tester.pump();
      expect(isSelected(tester, 'Earning points'), isTrue);
      // A single category shows no headers.
      expect(find.text('Getting started'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'log in');
      await tester.pump();

      expect(isSelected(tester, 'All'), isTrue);
      expect(find.text('How do I log in to my account?'), findsOneWidget);
      // Header for the login answer's category, plus its chip.
      expect(find.text('Account & security'), findsNWidgets(2));
      expect(find.text('No results found'), findsNothing);

      // Narrowing again hides the headers.
      final chip = find.widgetWithText(ChoiceChip, 'Account & security');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pump();
      expect(find.text('How do I log in to my account?'), findsOneWidget);
      expect(find.text('Account & security'), findsOneWidget);
      expect(find.text('Getting started'), findsOneWidget);
    });

    testWidgets('a query with no match shows the empty state', (tester) async {
      await pumpApp(tester, const FaqView());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();

      expect(find.text('No results found'), findsOneWidget);
      expect(
        find.text('Try another word, or email us at the top of this screen.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Clear search'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.text('No results found'), findsNothing);
    });

    testWidgets('searching "Transaction history" finds the balance answer',
        (tester) async {
      await pumpApp(tester, const FaqView());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Transaction history');
      await tester.pump();

      expect(
        find.text('Where can I see my points and history?'),
        findsOneWidget,
      );
    });

    testWidgets('chips have a 48 dp touch target', (tester) async {
      await pumpApp(tester, const FaqView());
      await tester.pump();

      final size = tester.getSize(find.widgetWithText(ChoiceChip, 'All'));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('support card', () {
    testWidgets('the copy button is labelled, 48 dp, copies and logs',
        (tester) async {
      await pumpApp(tester, const FaqView());
      await tester.pump();

      final copy = find.byTooltip('Copy support email');
      expect(copy, findsOneWidget);
      final size = tester.getSize(
        find.ancestor(of: copy, matching: find.byType(IconButton)),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tester.tap(copy);
      await tester.pump();

      expect(clipboard, ['custom_support@example.com']);
      expect(toasts.single.type, ToastType.success);
      expect(toasts.single.message, 'Email address copied.');
      expect(analyticsHarness.names, ['support_email_copied']);
    });

    testWidgets('the card reads as one email button', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, const FaqView());
      await tester.pump();

      expect(
        find.semantics.byLabel('Email support, custom_support@example.com'),
        findsOne,
      );
      expect(
        tester.getSemantics(find.byTooltip('Copy support email')),
        isSemantics(tooltip: 'Copy support email', isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('tapping the card opens mailto: and logs nothing',
        (tester) async {
      final opened = <(Uri, LaunchMode)>[];
      ExternalLinks.opener = (uri, mode) async {
        opened.add((uri, mode));
        return true;
      };

      await pumpApp(tester, const FaqView());
      await tester.pump();

      await tester.tap(find.text('Need help? Email us'));
      await tester.pump();

      expect(
        opened.single.$1.toString(),
        'mailto:custom_support@example.com',
      );
      expect(clipboard, isEmpty);
      expect(toasts, isEmpty);
      expect(analyticsHarness.names, isEmpty);
    });

    testWidgets('when nothing opens, the email is copied with an info toast',
        (tester) async {
      ExternalLinks.opener = (_, __) async => false;

      await pumpApp(tester, const FaqView());
      await tester.pump();

      await tester.tap(find.text('Need help? Email us'));
      await tester.pump();

      expect(clipboard, ['custom_support@example.com']);
      expect(toasts.single.type, ToastType.info);
      expect(
        toasts.single.message,
        "Couldn't open your email app. Email address copied.",
      );
      expect(analyticsHarness.names, ['support_email_copied']);
    });
  });

  Future<void> pumpSmall(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2.0),
          ),
          child: child,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('no overflow at 320x568 with 2.0x text, also when empty',
      (tester) async {
    await pumpSmall(tester, const FaqView());
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('No results found', skipOffstage: false), findsOneWidget);
  });
}
