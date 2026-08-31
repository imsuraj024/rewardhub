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
}
