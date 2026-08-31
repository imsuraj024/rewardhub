import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:rewardhub/core/widgets/app_button.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/login_controller.dart';
import 'package:rewardhub/features/auth/presentation/views/login_view.dart';

import '../../../../helpers/harness.dart';

/// Stand-ins for the controllers `LoginView` resolves via `Get.find`.
///
/// These **extend `GetxController`** rather than being mocktail mocks: `Get.put`
/// runs the GetX lifecycle on whatever it registers and reads `onStart`, which
/// is a callback *field*, not a method. A mock answers `null` for it and the
/// registration dies with "type 'Null' is not a subtype of type
/// 'InternalFinalCallback'". The declared `noSuchMethod` makes Dart emit
/// throwing stubs for the untouched rest of each interface, so an unexpected
/// call surfaces instead of silently returning null.
class _FakeAuthController extends GetxController implements AuthController {
  /// Real observable so reading [isLoading] inside `Obx` subscribes to it and
  /// flipping it rebuilds the CTA — exactly how the production getter behaves.
  final loading = false.obs;

  @override
  bool get isLoading => loading.value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLoginController extends GetxController implements LoginController {
  int onContinueCalls = 0;

  @override
  final formKey = GlobalKey<FormState>();

  @override
  final phoneController = TextEditingController();

  @override
  Future<void> onContinue() async {
    onContinueCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAuthController auth;
  late _FakeLoginController login;

  setUp(() {
    installGetTestHarness();

    auth = _FakeAuthController();
    login = _FakeLoginController();

    Get.put<AuthController>(auth);
    Get.put<LoginController>(login);
  });

  tearDown(resetGet);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const OverlaySupport.global(
        child: GetMaterialApp(home: LoginView()),
      ),
    );
    await tester.pump();
  }

  testWidgets('positive: renders header, welcome copy and CTA', (tester) async {
    await pump(tester);

    expect(find.text('Kitox Hardware'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Enter your mobile number to continue.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('MOBILE NUMBER'), findsOneWidget);
    expect(find.textContaining('Register'), findsWidgets);
  });

  testWidgets('positive: tapping Continue invokes controller.onContinue',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(login.onContinueCalls, 1);
  });

  testWidgets('edge: while loading the CTA shows a spinner and is disabled',
      (tester) async {
    auth.loading.value = true;
    await pump(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(login.onContinueCalls, 0);
  });
}
