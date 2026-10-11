import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';
import 'package:rewardhub/features/qr_scan/presentation/widgets/scan_result_sheet.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late Future<void> shown;
  late bool closed;

  Future<void> open(
    WidgetTester tester, {
    required bool success,
    String message = 'You earned 25 points.',
  }) async {
    closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                shown = ScanResultSheet.show(
                  context,
                  success: success,
                  message: message,
                ).then((_) => closed = true);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('positive: success shows the title, message and next action',
      (tester) async {
    await open(tester, success: true);

    expect(find.text('Points added'), findsOneWidget);
    expect(find.text('You earned 25 points.'), findsOneWidget);
    expect(find.text('Scan another code'), findsOneWidget);
    expect(
      tester.widget<AppIconBadge>(find.byType(AppIconBadge)).tone,
      AppIconBadgeTone.success,
    );
  });

  testWidgets('negative: failure shows the reason and "Scan again"',
      (tester) async {
    await open(tester, success: false, message: 'This code was already used.');

    expect(find.text("Couldn't add points"), findsOneWidget);
    expect(find.text('This code was already used.'), findsOneWidget);
    expect(find.text('Scan again'), findsOneWidget);
    expect(
      tester.widget<AppIconBadge>(find.byType(AppIconBadge)).tone,
      AppIconBadgeTone.error,
    );
  });

  testWidgets('positive: show completes when the button closes the sheet',
      (tester) async {
    await open(tester, success: true);
    expect(closed, isFalse);

    await tester.tap(find.text('Scan another code'));
    await tester.pumpAndSettle();
    await shown;

    expect(closed, isTrue);
    expect(find.text('Points added'), findsNothing);
  });

  testWidgets('edge: show completes on system back too', (tester) async {
    await open(tester, success: false);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await shown;

    expect(closed, isTrue);
  });

  testWidgets('positive: the result is announced as a live region',
      (tester) async {
    await open(tester, success: true);

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.container && (w.properties.liveRegion ?? false),
      ),
      findsOneWidget,
    );
  });
}
