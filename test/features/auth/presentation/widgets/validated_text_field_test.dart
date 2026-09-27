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

  testWidgets('edge: shows the Optional badge when optional is true',
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

    expect(find.text('Optional'), findsOneWidget);
  });

  testWidgets('edge: hides the Optional badge by default', (tester) async {
    await tester.pumpWidget(
      wrap(ValidatedTextField(label: 'Required', controller: controller)),
    );

    expect(find.text('Optional'), findsNothing);
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

  group('validation timing', () {
    String? tenDigits(String? v) =>
        (v ?? '').replaceAll(RegExp(r'\D'), '').length == 10
            ? null
            : 'Enter a valid 10-digit mobile number';

    Widget form({GlobalKey<FormState>? formKey}) => wrap(
          Form(
            key: formKey,
            child: Column(
              children: [
                ValidatedTextField(
                  label: 'Mobile number',
                  controller: controller,
                  validator: tenDigits,
                ),
                const TextField(key: Key('next')),
              ],
            ),
          ),
        );

    testWidgets('positive: quiet while typing, checked when focus leaves',
        (tester) async {
      await tester.pumpWidget(form());

      await tester.enterText(find.byType(TextFormField), '98');
      await tester.pump();
      expect(find.text('Enter a valid 10-digit mobile number'), findsNothing);

      await tester.tap(find.byKey(const Key('next')));
      await tester.pump();
      expect(
        find.text('Enter a valid 10-digit mobile number'),
        findsOneWidget,
      );
    });

    testWidgets('positive: after an error, the fixing keystroke clears it',
        (tester) async {
      await tester.pumpWidget(form());

      await tester.enterText(find.byType(TextFormField), '98');
      await tester.tap(find.byKey(const Key('next')));
      await tester.pump();
      expect(
        find.text('Enter a valid 10-digit mobile number'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField), '987654321');
      await tester.pump();
      expect(
        find.text('Enter a valid 10-digit mobile number'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.pump();
      expect(find.text('Enter a valid 10-digit mobile number'), findsNothing);
    });

    testWidgets('negative: tapping in and out without typing shows no error',
        (tester) async {
      await tester.pumpWidget(form());

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.tap(find.byKey(const Key('next')));
      await tester.pump();

      expect(find.text('Enter a valid 10-digit mobile number'), findsNothing);
    });

    testWidgets('edge: Form.validate shows the error; fixing clears it live',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(form(formKey: formKey));

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(
        find.text('Enter a valid 10-digit mobile number'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.pump();
      expect(find.text('Enter a valid 10-digit mobile number'), findsNothing);
    });
  });

  testWidgets('positive: passes keyboard and autofill options through',
      (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final submitted = <String>[];
    await tester.pumpWidget(
      wrap(
        ValidatedTextField(
          label: 'Name',
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onFieldSubmitted: submitted.add,
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode, same(focusNode));
    expect(field.textInputAction, TextInputAction.next);
    expect(field.autofillHints, [AutofillHints.name]);

    await tester.enterText(find.byType(TextFormField), 'Asha');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(submitted, ['Asha']);
  });

  testWidgets('edge: a supplied focus node is not disposed with the field',
      (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      wrap(
        ValidatedTextField(
          label: 'Name',
          controller: controller,
          focusNode: focusNode,
        ),
      ),
    );

    await tester.pumpWidget(wrap(const SizedBox.shrink()));

    // Still usable, so it was not disposed.
    expect(() => focusNode.addListener(() {}), returnsNormally);
  });

  testWidgets('edge: a long label wraps at 320 dp and 2.0x without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2.0),
          ),
          child: app!,
        ),
        // Auth forms always sit in a scroll view.
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: ValidatedTextField(
              label: 'UPI ID or Google Pay number',
              controller: controller,
              optional: true,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
