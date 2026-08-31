import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'package:rewardhub/core/services/shorebird_update_service.dart';
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

    expect(find.text('New Update Available'), findsOneWidget);
    expect(find.text('Update Now'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Current Version: Base Release'), findsOneWidget);
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

    expect(find.text('Update Installed!'), findsOneWidget);
    expect(find.text('Restart Now'), findsOneWidget);
    expect(find.text('Restart Later'), findsOneWidget);
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

    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();

    expect(find.text('Update Installed!'), findsOneWidget);
    expect(find.text('Restart Now'), findsOneWidget);
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

    await tester.tap(find.text('Restart Now'));
    await tester.pumpAndSettle();

    expect(restartCount, 1);
  });
}
