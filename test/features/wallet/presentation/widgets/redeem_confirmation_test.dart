import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/wallet/presentation/widgets/redeem_confirmation.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('canRedeem', () {
    test('negative: not loaded', () => expect(canRedeem(null), isFalse));
    test('negative: zero points', () => expect(canRedeem(0), isFalse));
    test('positive: any positive balance', () {
      expect(canRedeem(1), isTrue);
      expect(canRedeem(1250), isTrue);
    });
  });

  group('confirmRedemption', () {
    late Future<bool> result;

    Future<void> open(WidgetTester tester, {int points = 1250}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    result = confirmRedemption(context, points: points),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('positive: shows the question, the balance and both buttons',
        (tester) async {
      await open(tester);

      expect(find.text('Redeem your points?'), findsOneWidget);
      expect(
        find.text(
          "You have 1,250 points. We'll send a redemption request. "
          'The money goes to your saved payment details.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Send request'))
            .variant,
        AppButtonVariant.primary,
      );
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Cancel'))
            .variant,
        AppButtonVariant.outline,
      );
    });

    testWidgets('edge: one point is singular', (tester) async {
      await open(tester, points: 1);

      expect(find.textContaining('You have 1 point.'), findsOneWidget);
    });

    testWidgets('positive: Send request resolves true and closes the sheet',
        (tester) async {
      await open(tester);

      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
      expect(find.text('Redeem your points?'), findsNothing);
    });

    testWidgets('negative: Cancel resolves false', (tester) async {
      await open(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await result, isFalse);
    });

    testWidgets('negative: system back resolves false', (tester) async {
      await open(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(await result, isFalse);
      expect(find.text('Redeem your points?'), findsNothing);
    });

    testWidgets('negative: a scrim tap resolves false', (tester) async {
      await open(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(await result, isFalse);
    });

    testWidgets('edge: the copy makes no unconfirmed promises', (tester) async {
      await open(tester);

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      for (final banned in [
        'raised',
        'Session expired',
        'UPI',
        '₹',
        '[confirm'
      ]) {
        expect(texts, isNot(contains(banned)));
      }
    });
  });
}
