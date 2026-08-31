import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_field_label.dart';
import 'package:rewardhub/features/auth/presentation/widgets/validated_text_field.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('positive: renders the label', (tester) async {
    await tester.pumpWidget(
      wrap(ValidatedTextField(label: 'Full name', controller: controller)),
    );

    expect(find.byType(AuthFieldLabel), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
  });

  testWidgets('positive: shows a success tick once the value is valid',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        ValidatedTextField(
          label: 'Email',
          controller: controller,
          validator: (v) => (v != null && v.contains('@')) ? null : 'bad',
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'a@b.com');
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('positive: forwards keystrokes through onChanged',
      (tester) async {
    final values = <String>[];
    await tester.pumpWidget(
      wrap(
        ValidatedTextField(
          label: 'Name',
          controller: controller,
          onChanged: values.add,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Jo');
    await tester.pump();

    expect(values.last, 'Jo');
  });

  testWidgets('negative: no tick when the validator fails', (tester) async {
    await tester.pumpWidget(
      wrap(
        ValidatedTextField(
          label: 'Email',
          controller: controller,
          validator: (v) => (v != null && v.contains('@')) ? null : 'bad',
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('negative: never valid when no validator is supplied',
      (tester) async {
    await tester.pumpWidget(
      wrap(ValidatedTextField(label: 'Note', controller: controller)),
    );

    await tester.enterText(find.byType(TextFormField), 'anything');
    await tester.pump();

    // _computeValid returns false whenever validator == null.
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('negative: whitespace-only input is not considered valid',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        ValidatedTextField(
          label: 'Name',
          controller: controller,
          // Validator would pass, but a blank trimmed value short-circuits it.
          validator: (_) => null,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('edge: shows the OPTIONAL badge when optional is true',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        ValidatedTextField(
          label: 'Referral',
          controller: controller,
          optional: true,
        ),
      ),
    );

    expect(find.text('OPTIONAL'), findsOneWidget);
  });

  testWidgets('edge: hides the OPTIONAL badge by default', (tester) async {
    await tester.pumpWidget(
      wrap(ValidatedTextField(label: 'Required', controller: controller)),
    );

    expect(find.text('OPTIONAL'), findsNothing);
  });

  testWidgets('edge: renders a prefix icon and hint text', (tester) async {
    await tester.pumpWidget(
      wrap(
        ValidatedTextField(
          label: 'Phone',
          controller: controller,
          hintText: 'Enter number',
          prefixIcon: const Icon(Icons.phone),
        ),
      ),
    );

    expect(find.byIcon(Icons.phone), findsOneWidget);
    expect(find.text('Enter number'), findsOneWidget);
  });

  testWidgets('edge: pre-filled valid controller starts with a tick',
      (tester) async {
    controller.text = 'valid@x.com';
    await tester.pumpWidget(
      wrap(
        ValidatedTextField(
          label: 'Email',
          controller: controller,
          validator: (v) => (v != null && v.contains('@')) ? null : 'bad',
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
