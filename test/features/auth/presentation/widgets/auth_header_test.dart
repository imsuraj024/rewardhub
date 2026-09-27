import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/features/auth/presentation/widgets/auth_header.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // AuthHeader is always rendered inside a scroll view in the app
  // (login_view, otp_view, register_step_scaffold), which is what gives it
  // unbounded height. Wrapping it the same way here keeps the long-text case
  // honest instead of asserting against a constraint production never has.
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('positive: renders the title and subtitle', (tester) async {
    await tester.pumpWidget(
      wrap(const AuthHeader(title: 'Welcome', subtitle: 'Sign in to continue')),
    );

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
  });

  testWidgets('positive: renders the branded app icon image', (tester) async {
    await tester.pumpWidget(
      wrap(const AuthHeader(title: 'A', subtitle: 'B')),
    );

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('edge: renders empty title and subtitle strings', (tester) async {
    await tester.pumpWidget(wrap(const AuthHeader(title: '', subtitle: '')));

    expect(tester.takeException(), isNull);
    expect(find.byType(AuthHeader), findsOneWidget);
  });

  testWidgets('edge: renders very long title and subtitle', (tester) async {
    final title = 'Welcome ' * 30;
    final subtitle = 'Please continue ' * 30;
    await tester.pumpWidget(wrap(AuthHeader(title: title, subtitle: subtitle)));

    expect(tester.takeException(), isNull);
    expect(find.text(title), findsOneWidget);
    expect(find.text(subtitle), findsOneWidget);
  });

  testWidgets('positive: title and subtitle are centred', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AuthHeader(
          title: 'Kitox Hardware',
          subtitle: 'Scan, earn, and redeem rewards every day.',
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Kitox Hardware')).textAlign,
      TextAlign.center,
    );
    expect(
      tester
          .widget<Text>(find.text('Scan, earn, and redeem rewards every day.'))
          .textAlign,
      TextAlign.center,
    );
  });

  testWidgets('edge: the logo is decorative and has a fallback icon',
      (tester) async {
    await tester.pumpWidget(wrap(const AuthHeader(title: 'A', subtitle: 'B')));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.excludeFromSemantics, isTrue);
    expect(image.errorBuilder, isNotNull);
    final fallback = image.errorBuilder!(
      tester.element(find.byType(Image)),
      Exception('missing asset'),
      null,
    );
    expect(fallback, isA<Icon>());
    expect((fallback as Icon).icon, Icons.stars_rounded);
  });
}
