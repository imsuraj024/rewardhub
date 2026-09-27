import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_field_label.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('positive: renders the supplied text', (tester) async {
    await tester.pumpWidget(wrap(const AuthFieldLabel('EMAIL')));

    expect(find.text('EMAIL'), findsOneWidget);
  });

  testWidgets('positive: uses the fieldLabel role token', (tester) async {
    await tester.pumpWidget(wrap(const AuthFieldLabel('Phone')));

    final text = tester.widget<Text>(find.text('Phone'));
    expect(text.style?.letterSpacing, 0.1);
    expect(text.style?.fontWeight, FontWeight.w600);
    expect(text.style?.fontSize, 14);
  });

  testWidgets('edge: renders an empty label without throwing', (tester) async {
    await tester.pumpWidget(wrap(const AuthFieldLabel('')));

    expect(tester.takeException(), isNull);
    expect(find.byType(AuthFieldLabel), findsOneWidget);
  });

  testWidgets('edge: renders a long label', (tester) async {
    final label = 'FIELD ' * 25;
    await tester.pumpWidget(wrap(AuthFieldLabel(label)));

    expect(tester.takeException(), isNull);
    expect(find.text(label), findsOneWidget);
  });
}
