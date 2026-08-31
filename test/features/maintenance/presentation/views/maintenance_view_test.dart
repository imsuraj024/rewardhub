import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/features/maintenance/presentation/views/maintenance_view.dart';

import '../../../../helpers/harness.dart';

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

void main() {
  late MockRemoteConfigService mockRemoteConfig;

  setUp(() {
    installGetTestHarness();
    mockRemoteConfig = MockRemoteConfigService();

    when(() => mockRemoteConfig.maintenanceMessage).thenReturn(
      'RewardHub is undergoing scheduled maintenance. Please check back shortly.',
    );
    when(() => mockRemoteConfig.supportPhone).thenReturn('+91 98765 43210');
    when(() => mockRemoteConfig.supportEmail)
        .thenReturn('support@kitoxhardware.com');
    when(() => mockRemoteConfig.isMaintenanceMode).thenReturn(true);
    when(() => mockRemoteConfig.fetchAndActivate())
        .thenAnswer((_) async => true);

    Get.put<RemoteConfigService>(mockRemoteConfig);
  });

  tearDown(() async {
    await resetGet();
  });

  testWidgets('renders MaintenanceView with copy and support details',
      (tester) async {
    await pumpApp(tester, const MaintenanceView());
    await tester.pump();

    expect(find.text('Under Maintenance'), findsOneWidget);
    expect(
      find.text(
        'RewardHub is undergoing scheduled maintenance. Please check back shortly.',
      ),
      findsOneWidget,
    );
    expect(find.text('+91 98765 43210'), findsOneWidget);
    expect(find.text('support@kitoxhardware.com'), findsOneWidget);
    expect(find.text('Check Status'), findsOneWidget);
  });

  testWidgets('tapping Check Status triggers fetchAndActivate', (tester) async {
    await pumpApp(tester, const MaintenanceView());
    await tester.pump();

    final checkStatusButton = find.text('Check Status');
    expect(checkStatusButton, findsOneWidget);

    await tester.tap(checkStatusButton);
    await tester.pump();

    verify(() => mockRemoteConfig.fetchAndActivate()).called(1);
  });
}
