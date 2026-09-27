import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/features/auth/presentation/widgets/register_step_scaffold.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget step({bool canPop = true, VoidCallback? onPopBlocked}) =>
      RegisterStepScaffold(
        currentStep: 2,
        totalSteps: 3,
        title: 'Payment details',
        subtitle: 'Where should we send your money?',
        canPop: canPop,
        onPopBlocked: onPopBlocked,
        child: const Text('fields'),
      );

  /// Pushes [page] over a home route so system back has somewhere to go.
  Future<void> pushOverHome(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => page),
              ),
              child: const Text('home'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }

  testWidgets('positive: shows the sentence-case step label', (tester) async {
    await tester.pumpWidget(MaterialApp(home: step()));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('STEP 2 OF 3'), findsNothing);
    expect(find.text('fields'), findsOneWidget);
  });

  testWidgets('positive: the background uses the auth gradient token',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: step()));
    await tester.pumpAndSettle();

    final gradient = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          (w.decoration as BoxDecoration?)?.gradient ==
              AppColors.authBackgroundGradient,
    );
    expect(gradient, findsOneWidget);
  });

  testWidgets('positive: back leaves the step when canPop is true',
      (tester) async {
    await pushOverHome(tester, step());

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('fields'), findsNothing);
  });

  testWidgets('negative: canPop false keeps the step and calls onPopBlocked '
      'once', (tester) async {
    var blocked = 0;
    await pushOverHome(
      tester,
      step(canPop: false, onPopBlocked: () => blocked++),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('fields'), findsOneWidget);
    expect(blocked, 1);
  });
}
