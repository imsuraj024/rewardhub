import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/domain/usecases/get_recent_activities_usecase.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/home/presentation/views/home_view.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';
import 'package:rewardhub/features/wallet/presentation/controllers/wallet_controller.dart';

import '../../../../helpers/harness.dart';

class MockAuthController extends GetxController
    with Mock
    implements AuthController {}

class MockGetRecentActivitiesUseCase extends Mock
    implements GetRecentActivitiesUseCase {}

class MockProfileController extends GetxController
    with Mock
    implements ProfileController {}

class MockShellController extends GetxController
    with Mock
    implements ShellController {}

class MockWalletController extends GetxController
    with Mock
    implements WalletController {}

class MockAppAnalytics extends Mock implements AppAnalytics {}

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

void main() {
  late MockAuthController authController;
  late MockGetRecentActivitiesUseCase getRecentActivities;
  late MockProfileController profileController;
  late HomeController homeController;
  late MockShellController shellController;
  late MockWalletController walletController;
  late MockAppAnalytics analytics;
  late MockRemoteConfigService remoteConfig;

  setUp(() {
    installGetTestHarness();

    authController = MockAuthController();
    getRecentActivities = MockGetRecentActivitiesUseCase();
    profileController = MockProfileController();
    shellController = MockShellController();
    walletController = MockWalletController();
    analytics = MockAppAnalytics();
    remoteConfig = MockRemoteConfigService();

    when(() => authController.token).thenReturn('test_token');
    when(() => authController.tokenListenable).thenReturn(Rxn<String>('test_token'));
    when(() => getRecentActivities(any())).thenAnswer(
      (_) async => <RecentActivityModel>[],
    );

    homeController = HomeController(
      authController: authController,
      getRecentActivities: getRecentActivities,
    );

    when(() => walletController.isSubmitting).thenReturn(false.obs);

    when(() => profileController.state).thenReturn(
      ViewStateSuccess<ProfileModel>(
        ProfileModel(
          id: '1',
          name: 'John Doe',
          mobile: '9876543210',
          points: 100,
        ),
      ),
    );
    when(() => profileController.loadProfile()).thenAnswer((_) async {});
    when(() => remoteConfig.promotionalBanners).thenReturn([]);

    Get.put<ProfileController>(profileController);
    Get.put<HomeController>(homeController);
    Get.put<ShellController>(shellController);
    Get.put<WalletController>(walletController);
    Get.put<AppAnalytics>(analytics);
    Get.put<RemoteConfigService>(remoteConfig);
  });

  tearDown(resetGet);

  testWidgets(
      'renders Balance Card and How To Earn Points card guide on home screen',
      (tester) async {
    await pumpApp(tester, const HomeView());
    await tester.pumpAndSettle();

    expect(find.text('YOUR REWARD BALANCE'), findsOneWidget);

    final target = find.text('HOW TO EARN POINTS');
    await tester.scrollUntilVisible(target, 500, scrollable: find.byType(Scrollable));
    await tester.pumpAndSettle();

    expect(target, findsOneWidget);
    expect(find.text('Find Kitox QR'), findsOneWidget);
    expect(find.text('Scan in App'), findsOneWidget);
    expect(find.text('Claim Reward'), findsOneWidget);
  });
}
