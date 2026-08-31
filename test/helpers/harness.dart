import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:rewardhub/core/utils/app_toast.dart';

/// Shared test helpers for the Kitox Hardware suite.
///
/// Two pieces of GetX assume a live `GetMaterialApp`, and they need different
/// treatment in tests:
///
/// * **Navigation** (`Get.toNamed`, `Get.offAllNamed`) is guarded by
///   `Get.testMode`, which makes it a safe no-op.
/// * **Snackbars** (`AppToast` -> `Get.rawSnackbar`) ignore `Get.testMode`
///   entirely and reach straight for an overlay, so they need
///   [AppToast.presenter] to be redirected instead.
///
/// [installGetTestHarness] sets up both. For flows that must genuinely render a
/// toast or route, pump a real app with [pumpApp] instead.

/// Prepares a controller test that triggers GetX navigation or toasts.
///
/// Call from `setUp` — **not** `setUpAll`. `Get.reset()` calls
/// `Get.resetRootNavigator()` internally, which replaces the root
/// `GetMaterialController` with a fresh one whose `testMode` is back to
/// `false`. Arming it once per file therefore only protects the first test that
/// resets; every later navigation throws "contextless navigation without a
/// GetMaterialApp". Re-arming per test keeps it true for all of them.
///
/// Returns the list that captures toasts raised during the test, newest last.
List<RecordedToast> installGetTestHarness() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Get.testMode = true;
  return _installRecordingToasts();
}

/// Resets GetX's dependency container and navigation between tests.
///
/// Re-arms `Get.testMode` afterwards because `Get.reset()` clears it (see
/// [installGetTestHarness]), and clears the recorded-toast redirection so a
/// test that pumps a real app is not left with a stubbed [AppToast].
Future<void> resetGet() async {
  await Get.deleteAll(force: true);
  Get.reset();
  AppToast.presenter = null;
  Get.testMode = true;
}

/// A toast captured by the test harness instead of being rendered.
class RecordedToast {
  const RecordedToast(this.type, this.message, this.title);

  final ToastType type;
  final String message;
  final String? title;

  @override
  String toString() => 'RecordedToast($type, "$message", title: $title)';
}

/// Redirects [AppToast] into a list so controller tests can assert on toasts
/// without a live overlay.
List<RecordedToast> _installRecordingToasts() {
  final recorded = <RecordedToast>[];
  AppToast.presenter = (type, message, title) =>
      recorded.add(RecordedToast(type, message, title));
  return recorded;
}

/// Pumps [child] inside a minimal `GetMaterialApp` wrapped in `OverlaySupport`
/// so snackbars and named navigation work.
///
/// Register any controllers the widget resolves with `Get.put(...)` before
/// calling this, or pass an [initialBinding].
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<GetPage>? routes,
  Bindings? initialBinding,
}) async {
  await tester.pumpWidget(
    OverlaySupport.global(
      child: GetMaterialApp(
        home: Scaffold(body: child),
        getPages: routes,
        initialBinding: initialBinding,
      ),
    ),
  );
  await tester.pump();
}
