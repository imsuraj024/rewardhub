import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/qr_scan/presentation/controllers/qr_scan_controller.dart';
import 'package:rewardhub/features/qr_scan/presentation/views/qr_scan_view.dart';

import '../../../../helpers/harness.dart';

class MockMobileScannerController extends Mock
    implements MobileScannerController {}

class MockQrScanController extends GetxController
    with Mock
    implements QrScanController {}

class MockProfileController extends GetxController
    with Mock
    implements ProfileController {}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late MockQrScanController controller;

  setUp(() {
    installGetTestHarness();
    controller = MockQrScanController();

    when(() => controller.cameraStatus).thenReturn(PermissionStatus.denied.obs);
    when(() => controller.isSubmitting).thenReturn(false.obs);
    when(() => controller.requestCameraPermission()).thenAnswer((_) async {});

    Get.put<QrScanController>(controller);
  });

  tearDown(resetGet);

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpScan(WidgetTester tester, {double textScale = 1.0}) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: const QrScanView(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('hides loading overlay when isSubmitting is false',
      (tester) async {
    await pumpScan(tester);

    expect(find.text('Checking code…'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'shows semi-transparent loading overlay with spinner when isSubmitting is true',
      (tester) async {
    when(() => controller.isSubmitting).thenReturn(true.obs);

    await pumpScan(tester);

    expect(find.text('Checking code…'), findsOneWidget);
    expect(
      find.text('Please wait while we check this code.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('camera permission panel', () {
    testWidgets('positive: not asked yet → rationale, then the OS prompt',
        (tester) async {
      await pumpScan(tester);

      expect(find.text('Allow camera to scan'), findsOneWidget);
      expect(
          find.text('We need your camera to scan QR codes.'), findsOneWidget);
      verifyNever(() => controller.requestCameraPermission());

      await tester.tap(find.text('Allow camera'));
      await tester.pump();

      verify(() => controller.requestCameraPermission()).called(1);
    });

    for (final status in [
      PermissionStatus.permanentlyDenied,
      PermissionStatus.restricted,
    ]) {
      testWidgets('negative: ${status.name} → blocked panel', (tester) async {
        when(() => controller.cameraStatus).thenReturn(status.obs);

        await pumpScan(tester);

        expect(find.text('Camera is off'), findsOneWidget);
        expect(
          find.text('Tap Open settings, then turn on Camera.'),
          findsOneWidget,
        );
        expect(find.text('Open settings'), findsOneWidget);
        expect(find.text('Allow camera'), findsNothing);
      });
    }

    testWidgets('edge: provisional is treated as not asked yet',
        (tester) async {
      when(() => controller.cameraStatus)
          .thenReturn(PermissionStatus.provisional.obs);

      await pumpScan(tester);

      expect(find.text('Allow camera to scan'), findsOneWidget);
    });

    // 2.0x is a device check: the test font's full-em glyphs make the
    // one-line "Allow camera" button wider than the 256 dp panel, which
    // Inter is not.
    for (final scale in [1.0, 1.3]) {
      testWidgets('edge: no overflow at 320×568 and ${scale}x', (tester) async {
        useSize(tester, const Size(320, 568));

        await pumpScan(tester, textScale: scale);

        expect(tester.takeException(), isNull);
        expect(find.text('Allow camera'), findsOneWidget);
      });
    }
  });

  group('info card points', () {
    late Rx<ViewState<ProfileModel>> profileState;

    setUp(() {
      profileState = Rx<ViewState<ProfileModel>>(
        const ViewStateLoading<ProfileModel>(),
      );
      final profile = MockProfileController();
      // Reading the Rx inside the stub keeps the view's Obx reactive.
      when(() => profile.state).thenAnswer((_) => profileState.value);
      Get.put<ProfileController>(profile);
    });

    testWidgets('positive: the balance uses en_IN grouping and the unit',
        (tester) async {
      profileState.value = ViewStateSuccess<ProfileModel>(
        ProfileModel(id: '1', name: 'A', mobile: '9876543210', points: 123456),
      );

      await pumpScan(tester);

      expect(find.text('Your points'), findsOneWidget);
      expect(find.text('1,23,456 points'), findsOneWidget);
    });

    testWidgets('edge: loading shows a skeleton, not "..."', (tester) async {
      await pumpScan(tester);

      expect(find.byType(SkeletonBox), findsOneWidget);
      expect(find.text('...'), findsNothing);
    });

    testWidgets('negative: an error shows "—" read as "Not available"',
        (tester) async {
      profileState.value = const ViewStateError<ProfileModel>('down');

      await pumpScan(tester);

      final dash = tester.widget<Text>(find.text('—'));
      expect(dash.semanticsLabel, 'Not available');
    });
  });

  group('scanWindowSize', () {
    test('positive: caps at 220 when there is room', () {
      expect(
        scanWindowSize(const BoxConstraints(maxWidth: 360, maxHeight: 400)),
        220,
      );
    });

    test('edge: shrinks to fit a short camera area', () {
      expect(
        scanWindowSize(const BoxConstraints(maxWidth: 320, maxHeight: 180)),
        148,
      );
    });

    test('edge: never smaller than 96', () {
      expect(
        scanWindowSize(const BoxConstraints(maxWidth: 320, maxHeight: 100)),
        96,
      );
    });
  });
}
