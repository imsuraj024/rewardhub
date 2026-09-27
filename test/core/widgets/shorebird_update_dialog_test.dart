import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/shorebird_update_dialog.dart';

import '../../helpers/harness.dart';

class MockShorebirdUpdater extends Mock implements ShorebirdUpdater {}

void main() {
  late MockShorebirdUpdater mockUpdater;
  int restartCount = 0;

  setUp(() {
    mockUpdater = MockShorebirdUpdater();
    restartCount = 0;
    when(() => mockUpdater.isAvailable).thenReturn(true);
    when(() => mockUpdater.readCurrentPatch()).thenAnswer((_) async => null);
  });

  tearDown(resetGet);

  ShorebirdUpdateService createService() {
    return ShorebirdUpdateService(
      updater: mockUpdater,
      restartHandler: () async {
        restartCount++;
      },
    );
  }

  testWidgets('renders Update Available state by default', (tester) async {
    final service = createService();

    await pumpApp(
      tester,
      ShorebirdUpdateDialog(
        service: service,
        initialRestartReady: false,
      ),
    );

    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(
      find.text(
        'A new update is available for Kitox Hardware with important bug '
        'fixes and performance improvements.',
      ),
      findsOneWidget,
    );
    // Internal build wording is never shown.
    expect(find.textContaining('Patch'), findsNothing);
    expect(find.textContaining('Base Release'), findsNothing);
  });

  testWidgets('renders Restart Ready state when initialRestartReady is true',
      (tester) async {
    final service = createService();

    await pumpApp(
      tester,
      ShorebirdUpdateDialog(
        service: service,
        initialRestartReady: true,
      ),
    );

    expect(find.text('Update ready'), findsOneWidget);
    expect(find.text('Restart the app to finish updating.'), findsOneWidget);
    expect(find.text('Restart now'), findsOneWidget);
    expect(find.text('Restart later'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('tapping Update Now triggers download and transitions to restart ready',
      (tester) async {
    final service = createService();
    when(() => mockUpdater.update()).thenAnswer((_) async {});

    await pumpApp(
      tester,
      ShorebirdUpdateDialog(
        service: service,
        initialRestartReady: false,
      ),
    );

    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();

    expect(find.text('Update ready'), findsOneWidget);
    expect(find.text('Restart now'), findsOneWidget);
  });

  testWidgets('tapping Restart Now triggers app restart handler', (tester) async {
    final service = createService();

    await pumpApp(
      tester,
      ShorebirdUpdateDialog(
        service: service,
        initialRestartReady: true,
      ),
    );

    await tester.tap(find.text('Restart now'));
    await tester.pumpAndSettle();

    expect(restartCount, 1);
  });

  testWidgets('positive: the Later button has a visible outline border',
      (tester) async {
    await pumpApp(tester, ShorebirdUpdateDialog(service: createService()));

    final later = tester.widget<AppButton>(
      find.ancestor(of: find.text('Later'), matching: find.byType(AppButton)),
    );
    expect(later.variant, AppButtonVariant.outline);
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.ancestor(
          of: find.text('Later'),
          matching: find.byType(AppButton),
        ),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final border = (container.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, AppColors.outline);
    expect(border.top.width, 1);
  });

  testWidgets('edge: back is blocked while downloading, then allowed again',
      (tester) async {
    final service = createService();
    final download = Completer<void>();
    when(() => mockUpdater.update()).thenAnswer((_) => download.future);

    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Get.dialog<void>(
            ShorebirdUpdateDialog(service: service),
            barrierDismissible: false,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update now'));
    await tester.pump();
    expect(find.text('Downloading update…'), findsOneWidget);
    expect(find.text('Keep the app open until this finishes.'), findsOneWidget);

    // The download spinner never settles, so pump for a fixed time.
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ShorebirdUpdateDialog), findsOneWidget);

    download.complete();
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ShorebirdUpdateDialog), findsNothing);
  });
}
