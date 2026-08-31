import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/features/faq/presentation/views/faq_view.dart';

import '../../../../helpers/harness.dart';

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

void main() {
  late MockRemoteConfigService mockRemoteConfig;

  setUp(() {
    installGetTestHarness();
    mockRemoteConfig = MockRemoteConfigService();

    when(() => mockRemoteConfig.supportEmail)
        .thenReturn('custom_support@example.com');

    Get.put<RemoteConfigService>(mockRemoteConfig);
  });

  tearDown(() async {
    await resetGet();
  });

  testWidgets('renders FaqView with support email from RemoteConfigService',
      (tester) async {
    await pumpApp(tester, const FaqView());
    await tester.pump();

    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('custom_support@example.com'), findsOneWidget);
  });

  testWidgets('falls back to default kSupportEmail when RemoteConfigService is not registered',
      (tester) async {
    await resetGet();
    installGetTestHarness();

    await pumpApp(tester, const FaqView());
    await tester.pump();

    expect(find.text('support@kitoxhardware.com'), findsOneWidget);
  });
}
