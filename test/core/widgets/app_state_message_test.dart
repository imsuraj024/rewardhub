import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/core/widgets/app_icon_badge.dart';
import 'package:rewardhub/core/widgets/app_state_message.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrap(Widget child, {double textScale = 1.0}) => MaterialApp(
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: app!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );

  testWidgets('edge: every field filled fits 320 dp at 2.0x text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        AppStateMessage(
          icon: Icons.error_outline_rounded,
          tone: AppIconBadgeTone.error,
          title: "Couldn't load your transactions",
          message: 'Check your internet and try again in a moment.',
          // The test font's glyphs are full-em squares (about twice Inter's
          // width), so a short label stands in for "Try again" at 2.0x.
          actionLabel: 'Retry',
          onAction: () {},
        ),
        textScale: 2.0,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets('positive: the action fires onAction', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        AppStateMessage(
          icon: Icons.inbox_rounded,
          title: 'No transactions yet',
          actionLabel: 'Scan a code',
          onAction: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Scan a code'));
    expect(taps, 1);
  });

  testWidgets('negative: no button without an action label', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppStateMessage(
          icon: Icons.inbox_rounded,
          title: 'No transactions yet',
          onAction: () {},
        ),
      ),
    );

    expect(find.byType(AppButton), findsNothing);
    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('positive: the error tone is a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        const AppStateMessage(
          icon: Icons.error_outline_rounded,
          tone: AppIconBadgeTone.error,
          title: "Couldn't load",
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(AppStateMessage)),
      isSemantics(isLiveRegion: true, label: "Couldn't load"),
    );
    handle.dispose();
  });

  testWidgets('edge: other tones are not live regions', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        const AppStateMessage(icon: Icons.inbox_rounded, title: 'Empty'),
      ),
    );

    expect(
      tester.getSemantics(find.byType(AppStateMessage)),
      isSemantics(isLiveRegion: false),
    );
    handle.dispose();
  });
}
