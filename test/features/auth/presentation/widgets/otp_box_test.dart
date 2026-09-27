import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
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
    String? semanticLabel,
  }) =>
      wrap(
        OtpBox(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged ?? (_) {},
          semanticLabel: semanticLabel,
        ),
      );

  Border borderOf(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    return (container.decoration! as BoxDecoration).border! as Border;
  }

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

  testWidgets('positive: an empty box has a 1 px outline border',
      (tester) async {
    await tester.pumpWidget(buildBox());

    final border = borderOf(tester);
    expect(border.top.color, AppColors.outline);
    expect(border.top.width, 1);
  });

  testWidgets('positive: filled and focused boxes use primary borders',
      (tester) async {
    await tester.pumpWidget(buildBox());

    await tester.enterText(find.byType(TextField), '4');
    focusNode.unfocus();
    await tester.pump();
    expect(borderOf(tester).top.color, AppColors.primary);
    expect(borderOf(tester).top.width, 1.5);

    focusNode.requestFocus();
    await tester.pump();
    expect(borderOf(tester).top.color, AppColors.primary);
    expect(borderOf(tester).top.width, 2);
  });

  testWidgets('positive: the digit label is on the text field node',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildBox(semanticLabel: 'Digit 3 of 6'));

    expect(
      tester.getSemantics(find.byType(TextField)),
      isSemantics(label: 'Digit 3 of 6', isTextField: true),
    );
    handle.dispose();
  });

  testWidgets('edge: the box is at least 52 dp tall and grows with text',
      (tester) async {
    // As in the OTP screen: an Expanded box in a Row inside a scroll view.
    Widget row(double scale) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Row(
                  children: [
                    Expanded(
                      child: OtpBox(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(row(1.0));
    final normal = tester.getSize(find.byType(AnimatedContainer)).height;
    expect(normal, 52);

    await tester.pumpWidget(row(2.0));
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(AnimatedContainer)).height,
      greaterThan(normal),
    );
  });
}
