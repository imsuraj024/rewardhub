import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/features/auth/presentation/widgets/otp_box.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  Widget buildBox({
    ValueChanged<String>? onChanged,
    bool autofocus = false,
  }) =>
      wrap(
        OtpBox(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged ?? (_) {},
        ),
      );

  testWidgets('positive: renders a single-character TextField', (tester) async {
    await tester.pumpWidget(buildBox());

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLength, 1);
    expect(field.obscureText, isTrue);
    expect(field.keyboardType, TextInputType.number);
  });

  testWidgets('positive: reports the entered digit through onChanged',
      (tester) async {
    String? received;
    await tester.pumpWidget(buildBox(onChanged: (v) => received = v));

    await tester.enterText(find.byType(TextField), '7');
    await tester.pump();

    expect(received, '7');
    expect(controller.text, '7');
  });

  testWidgets('negative: strips non-digit characters via input formatter',
      (tester) async {
    String? received;
    await tester.pumpWidget(buildBox(onChanged: (v) => received = v));

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();

    // FilteringTextInputFormatter.digitsOnly rejects letters.
    expect(controller.text, isEmpty);
    expect(received, anyOf(isNull, isEmpty));
  });

  testWidgets('edge: focus change animates the border color', (tester) async {
    await tester.pumpWidget(buildBox());

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edge: advertises the oneTimeCode autofill hint', (tester) async {
    await tester.pumpWidget(buildBox());

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
  });

  testWidgets('edge: filled state persists a digit after entry',
      (tester) async {
    await tester.pumpWidget(buildBox());

    await tester.enterText(find.byType(TextField), '3');
    await tester.pump(const Duration(milliseconds: 200));

    expect(controller.text, '3');
    expect(tester.takeException(), isNull);
  });
}
