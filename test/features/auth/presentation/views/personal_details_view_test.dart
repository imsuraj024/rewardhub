import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_theme.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';
import 'package:rewardhub/features/auth/presentation/controllers/personal_details_controller.dart';
import 'package:rewardhub/features/auth/presentation/views/personal_details_view.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockRegistrationDraftStore extends Mock
    implements RegistrationDraftStore {}

const _termsSentence = 'I agree to the Terms of Service and Privacy Policy.';
const _termsError =
    'Please accept the Terms of Service and Privacy Policy to continue.';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late AnalyticsHarness analytics;
  late MockRegistrationDraftStore store;
  late PersonalDetailsController controller;
  late List<RecordedToast> toasts;

  setUpAll(() => registerFallbackValue(const RegistrationDraft()));

  setUp(() {
    toasts = installGetTestHarness();
    analytics = AnalyticsHarness();
    store = MockRegistrationDraftStore();
    when(() => store.read()).thenAnswer((_) async => const RegistrationDraft());
    when(() => store.save(any())).thenAnswer((_) async {});
    controller = Get.put(PersonalDetailsController(store, analytics.analytics));
  });

  tearDown(resetGet);

  Future<void> pumpStep(WidgetTester tester, {double textScale = 1.0}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: app!,
        ),
        home: const PersonalDetailsView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'Ramesh Kumar');
    await tester.enterText(find.byType(TextFormField).at(1), '9876543210');
    await tester.pump();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('positive: renders the new sentence-case copy', (tester) async {
    await pumpStep(tester);

    expect(find.text('Your details'), findsOneWidget);
    expect(find.text('Tell us who you are.'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Referral code'), findsOneWidget);
    expect(find.text('e.g. Ramesh Kumar'), findsOneWidget);
    expect(find.text('e.g. KX-0A1B-C2D3'), findsOneWidget);
    expect(find.text(_termsSentence, findRichText: true), findsOneWidget);
  });

  testWidgets('positive: tapping the sentence toggles the checkbox',
      (tester) async {
    await pumpStep(tester);

    await tester.ensureVisible(find.text(_termsSentence, findRichText: true));
    await tester.tap(find.text(_termsSentence, findRichText: true));
    await tester.pump();
    expect(controller.agreedToTerms.value, isTrue);

    await tester.tap(find.text(_termsSentence, findRichText: true));
    await tester.pump();
    expect(controller.agreedToTerms.value, isFalse);
  });

  testWidgets('positive: the terms row reads as one checkbox with its label',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpStep(tester);

    expect(
      tester.getSemantics(find.byType(Checkbox)),
      isSemantics(
        hasCheckedState: true,
        isChecked: false,
        label: _termsSentence,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('negative: Continue unticked shows the inline error, no toast',
      (tester) async {
    await pumpStep(tester);
    await fillValidForm(tester);

    await tapContinue(tester);

    expect(find.text(_termsError), findsOneWidget);
    expect(toasts, isEmpty);
    expect(analytics.names, contains('terms_not_accepted'));
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.side?.color, AppColors.error);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text(_termsError), findsNothing);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).side, isNull);
  });

  testWidgets('positive: Next moves Name -> Mobile -> Referral; Done closes',
      (tester) async {
    await pumpStep(tester);
    TextField field(int i) =>
        tester.widget<TextField>(find.byType(TextField).at(i));

    await tester.showKeyboard(find.byType(TextField).at(0));
    expect(field(0).textInputAction, TextInputAction.next);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(field(1).focusNode!.hasFocus, isTrue);

    expect(field(1).textInputAction, TextInputAction.next);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(field(2).focusNode!.hasFocus, isTrue);

    expect(field(2).textInputAction, TextInputAction.done);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(field(2).focusNode!.hasFocus, isFalse);
  });

  testWidgets('positive: name and mobile offer autofill hints', (tester) async {
    await pumpStep(tester);

    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).autofillHints,
      [AutofillHints.name],
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).autofillHints,
      [AutofillHints.telephoneNumber],
    );
    expect(find.byType(AutofillGroup), findsOneWidget);
  });

  testWidgets('positive: "Log in" returns to the page underneath',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PersonalDetailsView(),
                ),
              ),
              child: const Text('login page'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('login page'));
    await tester.pumpAndSettle();

    final logIn = find.textRange.ofSubstring('Log in');
    await tester.ensureVisible(find.text('Already have an account?  Log in',
        findRichText: true));
    await tester.tapOnText(logIn);
    await tester.pumpAndSettle();

    expect(find.text('login page'), findsOneWidget);
    expect(find.byType(PersonalDetailsView), findsNothing);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('edge: no overflow at 320 dp and ${scale}x text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpStep(tester, textScale: scale);
      await fillValidForm(tester);
      await tapContinue(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(_termsError), findsOneWidget);
    });
  }
}
