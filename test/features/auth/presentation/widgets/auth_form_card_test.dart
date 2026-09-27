import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_form_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('positive: renders its child', (tester) async {
    await tester.pumpWidget(
      wrap(const AuthFormCard(child: Text('form-body'))),
    );

    expect(find.text('form-body'), findsOneWidget);
  });

  testWidgets('positive: applies a rounded, shadowed decoration',
      (tester) async {
    await tester.pumpWidget(
      wrap(const AuthFormCard(child: SizedBox())),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AuthFormCard),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(24));
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('edge: stretches to the full available width', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 400,
          child: AuthFormCard(child: SizedBox(height: 10)),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AuthFormCard)).width, 400);
  });

  testWidgets('edge: renders a complex child subtree', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AuthFormCard(
          child: Column(
            children: [Text('one'), Text('two'), Text('three')],
          ),
        ),
      ),
    );

    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(find.text('three'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edge: compact phones get 16 dp padding, others 24 dp',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    EdgeInsetsGeometry? paddingAt(double width) {
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AuthFormCard),
          matching: find.byType(Container),
        ),
      );
      return container.padding;
    }

    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpWidget(wrap(const AuthFormCard(child: SizedBox())));
    expect(paddingAt(320), const EdgeInsets.all(16));

    tester.view.physicalSize = const Size(360, 640);
    await tester.pumpWidget(wrap(const AuthFormCard(child: SizedBox())));
    expect(paddingAt(360), const EdgeInsets.all(24));
  });
}
