import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/theme/app_theme.dart';
import 'package:rewardhub/features/auth/presentation/controllers/account_details_controller.dart';
import 'package:rewardhub/features/auth/presentation/views/account_details_view.dart';
import 'package:rewardhub/features/auth/presentation/widgets/validated_text_field.dart';

import '../../../../helpers/harness.dart';

/// Stand-in for the controller `AccountDetailsView` resolves via `Get.find`.
/// Extends `GetxController` for the same reason as the fakes in
/// `login_view_test.dart`.
class _FakeAccountDetailsController extends GetxController
    implements AccountDetailsController {
  int onNextCalls = 0;

  @override
  final formKey = GlobalKey<FormState>();
  @override
  final upiController = TextEditingController();
  @override
  final accountNumberController = TextEditingController();
  @override
  final ifscController = TextEditingController();
  @override
  final showBankDetails = false.obs;

  @override
  void revealBankDetails() => showBankDetails.value = true;

  @override
  Future<void> onNext() async => onNextCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late _FakeAccountDetailsController controller;

  setUp(() {
    installGetTestHarness();
    controller = Get.put<AccountDetailsController>(
      _FakeAccountDetailsController(),
    ) as _FakeAccountDetailsController;
  });

  tearDown(resetGet);

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

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
        home: const AccountDetailsView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(ValidatedTextField),
        ),
        matching: find.byType(TextField),
      );

  testWidgets('positive: renders the payout copy with no "OR" wording',
      (tester) async {
    await pumpStep(tester);

    expect(find.text('Payment details'), findsOneWidget);
    expect(find.text('Where should we send your money?'), findsOneWidget);
    expect(find.text('UPI ID or Google Pay number'), findsOneWidget);
    expect(find.text('name@okhdfcbank or 10-digit number'), findsOneWidget);
    expect(find.text('Bank account (optional)'), findsOneWidget);
    expect(find.text('Add bank account'), findsOneWidget);
    expect(find.textContaining('OR '), findsNothing);
  });

  testWidgets('edge: the bank label is not cut off at 320 dp', (tester) async {
    usePhone(tester);
    await pumpStep(tester);

    final label = tester.renderObject<RenderParagraph>(
      find.text('Bank account (optional)'),
    );
    expect(label.didExceedMaxLines, isFalse);
  });

  for (final showBank in [false, true]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('edge: no overflow at 320 dp, ${scale}x, bank shown: '
          '$showBank', (tester) async {
        usePhone(tester);
        controller.showBankDetails.value = showBank;
        await pumpStep(tester, textScale: scale);

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('positive: the UPI key is Done until bank fields are shown',
      (tester) async {
    await pumpStep(tester);
    expect(
      tester.widget<TextField>(field('UPI ID or Google Pay number'))
          .textInputAction,
      TextInputAction.done,
    );

    await tester.tap(find.text('Add bank account'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field('UPI ID or Google Pay number'))
          .textInputAction,
      TextInputAction.next,
    );
  });

  testWidgets('negative: account number stops at 18 digits, IFSC at 11',
      (tester) async {
    controller.showBankDetails.value = true;
    await pumpStep(tester);

    await tester.enterText(field('Account number'), '1234567890123456789');
    await tester.enterText(field('IFSC code'), 'sbin00012345');
    await tester.pump();

    expect(controller.accountNumberController.text, '123456789012345678');
    expect(controller.ifscController.text, 'SBIN0001234');
  });

  testWidgets('positive: Done on IFSC runs onNext', (tester) async {
    controller.showBankDetails.value = true;
    await pumpStep(tester);

    await tester.showKeyboard(field('IFSC code'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.onNextCalls, 1);
  });
}
