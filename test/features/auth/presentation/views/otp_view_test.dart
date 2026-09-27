import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_theme.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/otp_controller.dart';
import 'package:rewardhub/features/auth/presentation/views/otp_view.dart';
import 'package:rewardhub/features/auth/presentation/widgets/otp_box.dart';
import 'package:rewardhub/l10n/app_localizations.dart';

import '../../../../helpers/harness.dart';

/// Stand-ins for the controllers `OtpView` resolves via `Get.find`. They
/// extend `GetxController` for the same reason as the fakes in
/// `login_view_test.dart`.
class _FakeAuthController extends GetxController implements AuthController {
  // Observable-backed, like the real getters, so the view's Obx subscribes.
  final loading = false.obs;
  final error = RxnString();

  @override
  bool get isLoading => loading.value;

  @override
  String? get errorMessage => error.value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOtpController extends GetxController implements OtpController {
  int resends = 0;

  @override
  final controllers = List.generate(
    OtpController.otpLength,
    (_) => TextEditingController(),
  );
  @override
  final focusNodes = List.generate(OtpController.otpLength, (_) => FocusNode());
  @override
  final canResend = false.obs;

  @override
  String get maskedPhone => '+91 ••••• 43210';

  @override
  String get timerLabel => '04:59';

  @override
  void onDigitChanged(int index, String value) {}

  @override
  Future<void> onVerify() async {}

  @override
  Future<void> onResend() async => resends++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late _FakeOtpController otp;

  setUp(() {
    installGetTestHarness();
    Get.put<AuthController>(_FakeAuthController());
    otp = Get.put<OtpController>(_FakeOtpController()) as _FakeOtpController;
  });

  tearDown(resetGet);

  Future<void> pumpOtp(WidgetTester tester, {double width = 400}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OtpView(),
      ),
    );
    await tester.pump();
  }

  Color? resendColor(WidgetTester tester) {
    final button = find.byType(TextButton);
    final text = find.descendant(of: button, matching: find.byType(Text));
    return DefaultTextStyle.of(tester.element(text)).style.color;
  }

  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets('edge: the six boxes fit at $width dp', (tester) async {
      // Hides the countdown pill (outside DS-24), whose caps copy is too wide
      // in the test font, so only the OTP row is measured here.
      otp.canResend.value = true;
      await pumpOtp(tester, width: width);

      expect(tester.takeException(), isNull);
      expect(find.byType(OtpBox), findsNWidgets(OtpController.otpLength));
    });
  }

  testWidgets('edge: at 320 dp each box is at least 33 dp wide',
      (tester) async {
    otp.canResend.value = true;
    await pumpOtp(tester, width: 320);

    for (final box in tester.widgetList(find.byType(OtpBox))) {
      final width = tester.getSize(find.byWidget(box)).width;
      expect(width, greaterThanOrEqualTo(33));
    }
  });

  testWidgets('positive: Resend is a real button, greyed while waiting',
      (tester) async {
    await pumpOtp(tester);

    final resend = find.byType(TextButton);
    expect(resend, findsOneWidget);
    expect(tester.getSize(resend).height, greaterThanOrEqualTo(48));
    expect(tester.widget<TextButton>(resend).onPressed, isNull);
    expect(resendColor(tester), AppColors.onSurfaceVariant);

    otp.canResend.value = true;
    // Material animates the text colour change.
    await tester.pumpAndSettle();
    expect(resendColor(tester), AppColors.primary);

    await tester.tap(resend);
    expect(otp.resends, 1);
  });

  testWidgets('positive: each box is labelled with its digit position',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpOtp(tester);

    expect(
      tester.getSemantics(find.byType(TextField).at(2)),
      isSemantics(label: 'Digit 3 of 6', isTextField: true),
    );
    handle.dispose();
  });
}
