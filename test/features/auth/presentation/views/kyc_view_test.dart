import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/theme/app_theme.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/auth/presentation/controllers/kyc_controller.dart';
import 'package:rewardhub/features/auth/presentation/views/kyc_view.dart';
import 'package:rewardhub/features/auth/presentation/widgets/dashed_border.dart';

import '../../../../helpers/harness.dart';

/// Stand-in for the controller `KycView` resolves via `Get.find`. Extends
/// `GetxController` for the same reason as the fakes in `login_view_test.dart`.
class _FakeKycController extends GetxController implements KycController {
  final loading = false.obs;
  final picked = <ImageSource>[];

  @override
  final aadhaarPath = ''.obs;
  @override
  final selfiePath = ''.obs;

  @override
  bool get isLoading => loading.value;

  @override
  Future<void> pickAadhaar(ImageSource source) async => picked.add(source);

  @override
  Future<void> pickSelfie() async {}

  @override
  Future<void> onSubmit() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late _FakeKycController controller;
  late List<RecordedToast> toasts;

  setUp(() {
    toasts = installGetTestHarness();
    controller =
        Get.put<KycController>(_FakeKycController()) as _FakeKycController;
  });

  tearDown(resetGet);

  /// Pushes the KYC step over a home route so back has somewhere to go.
  Future<void> pushStep(WidgetTester tester, {double textScale = 1.0}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: app!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const KycView()),
              ),
              child: const Text('step 2'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('step 2'));
    await tester.pumpAndSettle();
  }

  AppButton button(WidgetTester tester, String label) => tester.widget(
        find.ancestor(of: find.text(label), matching: find.byType(AppButton)),
      );

  testWidgets('positive: renders the new copy', (tester) async {
    await pushStep(tester);

    expect(find.text('Verify your identity'), findsOneWidget);
    expect(find.text('Aadhaar card photo'), findsOneWidget);
    expect(find.text('Add Aadhaar photo'), findsOneWidget);
    expect(find.text('Front side. All 4 corners visible.'), findsOneWidget);
    expect(find.text('Selfie'), findsOneWidget);
    expect(find.text('Submit for review'), findsOneWidget);
  });

  testWidgets('negative: while uploading, back stays and explains why',
      (tester) async {
    await pushStep(tester);
    controller.loading.value = true;
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(KycView), findsOneWidget);
    expect(toasts.single.type, ToastType.info);
    expect(toasts.single.message, "Please wait. We're sending your details.");
    expect(button(tester, 'Back').onPressed, isNull);
    expect(button(tester, 'Submit for review').isLoading, isTrue);
  });

  testWidgets('positive: once the upload ends, back works again',
      (tester) async {
    await pushStep(tester);
    controller.loading.value = true;
    await tester.pump();
    controller.loading.value = false;
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(KycView), findsNothing);
    expect(find.text('step 2'), findsOneWidget);
    expect(toasts, isEmpty);
  });

  testWidgets('positive: the empty slot has an outline-coloured dashed border',
      (tester) async {
    await pushStep(tester);

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<DashedRRectPainter>()
        .toList();
    expect(painters, hasLength(2));
    for (final painter in painters) {
      expect(painter.color, AppColors.outline);
      expect(painter.radius, AppRadius.lg);
    }
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('edge: empty tiles fit 320 dp at ${scale}x text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pushStep(tester, textScale: scale);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('positive: the Aadhaar sheet offers camera and gallery',
      (tester) async {
    await pushStep(tester);

    await tester.tap(find.text('Add Aadhaar photo'));
    await tester.pumpAndSettle();
    expect(find.text('Add Aadhaar photo'), findsNWidgets(2));
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsNothing);
    expect(controller.picked, [ImageSource.camera]);
  });

  testWidgets('edge: a draft photo that no longer exists shows a recovery '
      'tile, never "Added"', (tester) async {
    controller.aadhaarPath.value = '/no/such/dir/aadhaar.jpg';
    await tester.runAsync(() async {
      await pushStep(tester);
      // Let the real file read fail outside the fake clock.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(find.text('Photo not found. Tap to add it again.'), findsOneWidget);
    expect(find.text('Added'), findsNothing);
  });
}
