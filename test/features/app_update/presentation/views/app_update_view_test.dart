import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/features/app_update/presentation/views/app_update_view.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';

import '../../../../helpers/harness.dart';

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

class MockAuthController extends GetxController
    with Mock
    implements AuthController {}

void main() {
  late MockRemoteConfigService mockRemoteConfig;
  late MockAuthController mockAuth;

  setUp(() {
    installGetTestHarness();
    mockRemoteConfig = MockRemoteConfigService();
    mockAuth = MockAuthController();

    when(() => mockRemoteConfig.releaseNotes).thenReturn(
      '["Super fast scan engine", "Instant UPI settlements"]',
    );
    when(() => mockAuth.isAuthenticated).thenReturn(false);

    Get.put<RemoteConfigService>(mockRemoteConfig);
    Get.put<AuthController>(mockAuth);
  });

  tearDown(() async {
    await resetGet();
  });

  testWidgets(
      'renders AppUpdateView with JSON release notes array and store buttons',
      (tester) async {
    await pumpApp(tester, const AppUpdateView());
    await tester.pump();

    expect(find.text('New Version Available'), findsOneWidget);
    expect(find.text("What's New in this Update"), findsOneWidget);
    expect(find.text('Super fast scan engine'), findsOneWidget);
    expect(find.text('Instant UPI settlements'), findsOneWidget);
    expect(find.textContaining('Update on'), findsOneWidget);
  });

  testWidgets('renders AppUpdateView with JSON object format {"notes": [...]}',
      (tester) async {
    when(() => mockRemoteConfig.releaseNotes).thenReturn(
      '{"notes": ["Quick login", "Dark mode enhancements"]}',
    );

    await pumpApp(tester, const AppUpdateView());
    await tester.pump();

    expect(find.text("What's New in this Update"), findsOneWidget);
    expect(find.text('Quick login'), findsOneWidget);
    expect(find.text('Dark mode enhancements'), findsOneWidget);
  });

  testWidgets(
      'hides What is New section completely when releaseNotes is empty or null',
      (tester) async {
    when(() => mockRemoteConfig.releaseNotes).thenReturn(null);

    await pumpApp(tester, const AppUpdateView());
    await tester.pump();

    expect(find.text("What's New in this Update"), findsNothing);
    expect(find.text('New Version Available'), findsOneWidget);
  });

  testWidgets(
      'hides What is New section when releaseNotes is empty JSON array []',
      (tester) async {
    when(() => mockRemoteConfig.releaseNotes).thenReturn('[]');

    await pumpApp(tester, const AppUpdateView());
    await tester.pump();

    expect(find.text("What's New in this Update"), findsNothing);
    expect(find.text('New Version Available'), findsOneWidget);
  });
}
