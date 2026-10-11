import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/external_links.dart';
import 'package:rewardhub/features/maintenance/presentation/views/maintenance_view.dart';

import '../../../../helpers/harness.dart';

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

void main() {
  late MockRemoteConfigService mockRemoteConfig;
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

    when(() => mockRemoteConfig.maintenanceMessage).thenReturn(
      'RewardHub is undergoing scheduled maintenance. Please check back shortly.',
    );
    when(() => mockRemoteConfig.supportPhone).thenReturn('+91 98765 43210');
    when(() => mockRemoteConfig.supportEmail)
        .thenReturn('support@kitoxhardware.com');
    when(() => mockRemoteConfig.isMaintenanceMode).thenReturn(true);
    when(() => mockRemoteConfig.fetchAndActivate())
        .thenAnswer((_) async => true);

    Get.put<RemoteConfigService>(mockRemoteConfig);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    ExternalLinks.opener = null;
    await resetGet();
  });

  testWidgets('renders MaintenanceView with copy and support details',
      (tester) async {
    await pumpApp(tester, const MaintenanceView());
    await tester.pump();

    expect(find.text('Under maintenance'), findsOneWidget);
    expect(
      find.text(
        'RewardHub is undergoing scheduled maintenance. Please check back shortly.',
      ),
      findsOneWidget,
    );
    expect(find.text('+91 98765 43210'), findsOneWidget);
    expect(find.text('support@kitoxhardware.com'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Call support'), findsOneWidget);
    expect(find.text('Email support'), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('tapping Try again triggers fetchAndActivate', (tester) async {
    await pumpApp(tester, const MaintenanceView());
    await tester.pump();

    final tryAgainButton = find.text('Try again');
    expect(tryAgainButton, findsOneWidget);

    await tester.tap(tryAgainButton);
    await tester.pump();

    verify(() => mockRemoteConfig.fetchAndActivate()).called(1);
    expect(toasts.single.type, ToastType.info);
    expect(
      toasts.single.message,
      'Still under maintenance. Please try again later.',
    );
    expect(toasts.single.title, isNull);
  });

  testWidgets('rows and copy buttons are labelled buttons', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, const MaintenanceView());
    await tester.pump();

    expect(
      tester.getSemantics(find.text('Call support')),
      isSemantics(
        label: 'Call support, +91 98765 43210',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      find.semantics.byLabel('Email support, support@kitoxhardware.com'),
      findsOne,
    );
    expect(
      tester.getSemantics(find.byTooltip('Copy phone number')),
      isSemantics(tooltip: 'Copy phone number', isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('tapping the phone row dials tel:', (tester) async {
    final opened = <Uri>[];
    ExternalLinks.opener = (uri, _) async {
      opened.add(uri);
      return true;
    };

    await pumpApp(tester, const MaintenanceView());
    await tester.pump();

    await tester.tap(find.text('Call support'));
    await tester.pump();

    expect(opened.single.toString(), 'tel:+919876543210');
    expect(clipboard, isEmpty);
    expect(toasts, isEmpty);
  });

  testWidgets('when no phone app opens, the number is copied', (tester) async {
    ExternalLinks.opener = (_, __) async => false;

    await pumpApp(tester, const MaintenanceView());
    await tester.pump();

    await tester.tap(find.text('Call support'));
    await tester.pump();

    expect(clipboard, ['+91 98765 43210']);
    expect(toasts.single.type, ToastType.info);
    expect(
      toasts.single.message,
      "Couldn't open the phone app. Phone number copied.",
    );
  });

  testWidgets('the copy buttons copy with full-sentence toasts',
      (tester) async {
    await pumpApp(tester, const MaintenanceView());
    await tester.pump();

    await tester.tap(find.byTooltip('Copy phone number'));
    await tester.pump();
    await tester.tap(find.byTooltip('Copy email address'));
    await tester.pump();

    expect(clipboard, ['+91 98765 43210', 'support@kitoxhardware.com']);
    expect(toasts.map((t) => t.message), [
      'Phone number copied.',
      'Email address copied.',
    ]);
  });

  testWidgets('a blank phone hides its row; both blank hide the card',
      (tester) async {
    when(() => mockRemoteConfig.supportPhone).thenReturn('');

    await pumpApp(tester, const MaintenanceView());
    await tester.pump();

    expect(find.text('Call support'), findsNothing);
    expect(find.text('Email support'), findsOneWidget);

    when(() => mockRemoteConfig.supportEmail).thenReturn(' ');
    await pumpApp(tester, const MaintenanceView(key: ValueKey('both-blank')));
    await tester.pump();

    expect(find.text('Need help now?'), findsNothing);
  });

  testWidgets('scrolls at 320x568 with 2.0x text and Try again is reachable',
      (tester) async {
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
          child: const MaintenanceView(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Try again'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Try again'));
    await tester.pump();
    verify(() => mockRemoteConfig.fetchAndActivate()).called(1);
  });
}
