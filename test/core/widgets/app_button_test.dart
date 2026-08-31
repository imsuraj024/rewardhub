import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/widgets/app_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders its label', (tester) async {
    await tester.pumpWidget(
      wrap(AppButton(label: 'Continue', onPressed: () {})),
    );

    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('fires onPressed when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(AppButton(label: 'Tap', onPressed: () => taps++)),
    );

    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });

  testWidgets('does not fire while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(AppButton(label: 'Wait', isLoading: true, onPressed: () => taps++)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(taps, 0);
  });

  testWidgets('is inert when onPressed is null', (tester) async {
    await tester.pumpWidget(
      wrap(const AppButton(label: 'Disabled', onPressed: null)),
    );

    await tester.tap(find.byType(AppButton));
    // No callback to assert on — the test passes if the tap does not throw.
    expect(find.text('Disabled'), findsOneWidget);
  });
}
