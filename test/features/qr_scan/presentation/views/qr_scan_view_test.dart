import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rewardhub/features/qr_scan/presentation/controllers/qr_scan_controller.dart';
import 'package:rewardhub/features/qr_scan/presentation/views/qr_scan_view.dart';

import '../../../../helpers/harness.dart';

class MockMobileScannerController extends Mock
    implements MobileScannerController {}

class MockQrScanController extends GetxController
    with Mock
    implements QrScanController {}

void main() {
  late MockQrScanController controller;

  setUp(() {
    installGetTestHarness();
    controller = MockQrScanController();

    when(() => controller.cameraStatus)
        .thenReturn(PermissionStatus.denied.obs);
    when(() => controller.isSubmitting).thenReturn(false.obs);
    when(() => controller.requestCameraPermission()).thenAnswer((_) async {});

    Get.put<QrScanController>(controller);
  });

  tearDown(resetGet);

  testWidgets('hides loading overlay when isSubmitting is false', (tester) async {
    await pumpApp(tester, const QrScanView());
    await tester.pump();

    expect(find.text('Verifying QR Code...'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'shows semi-transparent loading overlay with spinner when isSubmitting is true',
      (tester) async {
    when(() => controller.isSubmitting).thenReturn(true.obs);

    await pumpApp(tester, const QrScanView());
    await tester.pump();

    expect(find.text('Verifying QR Code...'), findsOneWidget);
    expect(
      find.text('Please hold on while we claim your points.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
