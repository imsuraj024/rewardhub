import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/utils/app_toast.dart';

import '../../helpers/harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  tearDown(() async {
    await resetGet();
  });

  // Builds the overlay and finishes the snackbar enter animation.
  Future<void> settleToast(WidgetTester tester) async {
    await tester.pump();
    await tester.pumpAndSettle();
  }

  // Lets the 3s display timer elapse so the snackbar auto-dismisses, then
  // finishes the exit animation — leaving no pending timers for the next test.
  Future<void> dismissToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('positive: success shows the message and icon, no title',
      (tester) async {
    await pumpApp(tester, const SizedBox.shrink());

    AppToast.success('Profile updated');
    await settleToast(tester);

    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('Success'), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await dismissToast(tester);
  });

  testWidgets('positive: error shows only its message and icon',
      (tester) async {
    await pumpApp(tester, const SizedBox.shrink());

    AppToast.error('Upload failed');
    await settleToast(tester);

    expect(find.text('Upload failed'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);

    await dismissToast(tester);
  });

  testWidgets('positive: warning shows only its message and icon',
      (tester) async {
    await pumpApp(tester, const SizedBox.shrink());

    AppToast.warning('Battery low');
    await settleToast(tester);

    expect(find.text('Battery low'), findsOneWidget);
    expect(find.text('Heads up'), findsNothing);
    expect(find.byIcon(Icons.warning_rounded), findsOneWidget);

    await dismissToast(tester);
  });

  testWidgets('positive: info shows only its message and icon',
      (tester) async {
    await pumpApp(tester, const SizedBox.shrink());

    AppToast.info('New feature available');
    await settleToast(tester);

    expect(find.text('New feature available'), findsOneWidget);
    expect(find.text('Info'), findsNothing);
    expect(find.byIcon(Icons.info_rounded), findsOneWidget);

    await dismissToast(tester);
  });

  testWidgets('edge: a title appears only when one is passed', (tester) async {
    await pumpApp(tester, const SizedBox.shrink());

    AppToast.error('Disk is full', title: 'Storage error');
    await settleToast(tester);

    expect(find.text('Storage error'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.text('Disk is full'), findsOneWidget);

    await dismissToast(tester);
  });

  testWidgets('edge: calling twice does not throw', (tester) async {
    await pumpApp(tester, const SizedBox.shrink());

    AppToast.success('first');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Second call closes the duplicate before showing the new one.
    AppToast.success('second');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Drain both snackbars from the queue so the next test starts clean.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('edge: renders an empty message without throwing',
      (tester) async {
    await pumpApp(tester, const SizedBox.shrink());

    AppToast.info('');
    await settleToast(tester);

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.info_rounded), findsOneWidget);
    expect(find.text('Info'), findsNothing);

    await dismissToast(tester);
  });

  testWidgets('edge: renders a very long message', (tester) async {
    await pumpApp(tester, const SizedBox.shrink());

    final message = 'Something happened. ' * 20;
    AppToast.warning(message);
    await settleToast(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(message), findsOneWidget);

    await dismissToast(tester);
  });

  testWidgets('positive: the message is 14 px in the on-container colour',
      (tester) async {
    await pumpApp(tester, const SizedBox.shrink());

    AppToast.error("You're offline. Check your internet and try again.");
    await settleToast(tester);

    final text = tester.widget<Text>(
      find.text("You're offline. Check your internet and try again."),
    );
    expect(text.style?.fontSize, 14);
    expect(text.style?.color, AppColors.onErrorContainer);

    await dismissToast(tester);
  });

  testWidgets('positive: a passed title uses the on-container colour',
      (tester) async {
    await pumpApp(tester, const SizedBox.shrink());

    AppToast.success('Saved', title: 'Profile');
    await settleToast(tester);

    final title = tester.widget<Text>(find.text('Profile'));
    expect(title.style?.color, AppColors.onSuccessContainer);
    expect(title.style?.fontWeight, FontWeight.w700);

    await dismissToast(tester);
  });
}
