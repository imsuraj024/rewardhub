import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/widgets/app_top_bar.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(appBar: child as PreferredSizeWidget));

  testWidgets('positive: renders default title',
      (tester) async {
    await tester.pumpWidget(wrap(const AppTopBar()));

    expect(find.text('Kitox Hardware'), findsOneWidget);
  });

  testWidgets('positive: renders a custom title', (tester) async {
    await tester.pumpWidget(wrap(const AppTopBar(title: 'My Rewards')));

    expect(find.text('My Rewards'), findsOneWidget);
    expect(find.text('Kitox Hardware'), findsNothing);
  });

  testWidgets('edge: exposes a toolbar-height preferredSize', (tester) async {
    const bar = AppTopBar();
    expect(bar.preferredSize.height, kToolbarHeight);
  });

  testWidgets('edge: renders an empty title without overflowing',
      (tester) async {
    await tester.pumpWidget(wrap(const AppTopBar(title: '')));
    expect(tester.takeException(), isNull);
    expect(find.byType(AppTopBar), findsOneWidget);
  });

  testWidgets('edge: renders a very long title', (tester) async {
    final longTitle = 'Reward ' * 40;
    await tester.pumpWidget(wrap(AppTopBar(title: longTitle)));

    expect(tester.takeException(), isNull);
    expect(find.text(longTitle), findsOneWidget);
  });

  testWidgets('positive: renders bottom divider when showDivider is true',
      (tester) async {
    const bar = AppTopBar(showDivider: true);
    expect(bar.preferredSize.height, kToolbarHeight);

    await tester.pumpWidget(wrap(const AppTopBar(showDivider: true)));
    expect(tester.takeException(), isNull);
    expect(find.byType(PreferredSize), findsOneWidget);
  });

  testWidgets('positive: renders no divider by default', (tester) async {
    await tester.pumpWidget(wrap(const AppTopBar()));

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.bottom, isNull);
    expect(find.byType(PreferredSize), findsNothing);
  });

  testWidgets('positive: renders a subtitle under the title within 56 dp',
      (tester) async {
    await tester.pumpWidget(
      wrap(const AppTopBar(title: 'Catalogue', subtitle: 'Page 3 of 40')),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Catalogue'), findsOneWidget);
    expect(find.text('Page 3 of 40'), findsOneWidget);
    final titleTop = tester.getTopLeft(find.text('Catalogue')).dy;
    final subtitleBottom = tester.getBottomLeft(find.text('Page 3 of 40')).dy;
    expect(subtitleBottom - titleTop, lessThanOrEqualTo(kToolbarHeight));
    expect(
      tester.getTopLeft(find.text('Page 3 of 40')).dy,
      greaterThan(titleTop),
    );
  });

  testWidgets('positive: action tooltips describe what they open',
      (tester) async {
    await tester.pumpWidget(
      wrap(AppTopBar(onHelpTap: () {}, onNotificationTap: () {})),
    );

    expect(find.byTooltip('Open help'), findsOneWidget);
    expect(find.byTooltip('Open notifications'), findsOneWidget);
  });
}
