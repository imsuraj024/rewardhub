import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/profile/presentation/views/profile_view.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

class MockShorebirdUpdateService extends GetxService
    with Mock
    implements ShorebirdUpdateService {}

class MockAuthController extends GetxController
    with Mock
    implements AuthController {}

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

/// The profile screen reads `PackageInfo` once per process and caches the
/// future. A completed future delivers its result through the zone it was
/// created in, and every `testWidgets` runs in its own fake-async zone, so the
/// resolved version is only observable in the first test that builds the
/// screen. Keep this file to a single test.
void main() {
  setUp(() {
    installGetTestHarness();
    PackageInfo.setMockInitialValues(
      appName: 'Kitox Hardware',
      packageName: 'com.loyalty.rewardhub',
      version: '1.2.0',
      buildNumber: '6',
      buildSignature: '',
    );

    final analyticsHarness = AnalyticsHarness();
    final mockRemoteConfig = MockRemoteConfigService();
    final mockShorebird = MockShorebirdUpdateService();
    final mockAuth = MockAuthController();
    final mockGetProfile = MockGetProfileUseCase();

    when(() => mockAuth.token).thenReturn('token');
    when(() => mockAuth.tokenListenable).thenReturn(Rxn<String>('token'));
    when(() => mockGetProfile.call(any())).thenAnswer(
      (_) async => ProfileModel(
        id: 'user-1',
        name: 'Suraj Kumar',
        mobile: '9876543210',
        points: 450,
      ),
    );
    when(() => mockRemoteConfig.releaseNotes).thenReturn('["Bug fixes"]');
    when(() => mockShorebird.currentPatchNumber).thenReturn(3);

    Get.put<ProfileController>(
      ProfileController(
        authController: mockAuth,
        getProfile: mockGetProfile,
        analytics: analyticsHarness.analytics,
      ),
    );
    Get.put<RemoteConfigService>(mockRemoteConfig);
    Get.put<ShorebirdUpdateService>(mockShorebird);
    Get.put<AuthController>(mockAuth);
    Get.put(analyticsHarness.analytics);
  });

  tearDown(resetGet);

  testWidgets(
      'footer reads "Version x (patch)  •  Kitox Hardware" and '
      "What's new shows the version", (tester) async {
    await pumpApp(tester, const ProfileView());
    await tester.pumpAndSettle();

    expect(
      find.text('Version 1.2.0 (3)  •  Kitox Hardware'),
      findsOneWidget,
    );
    expect(find.textContaining('PATCH'), findsNothing);
    expect(find.textContaining('VERSION'), findsNothing);

    await tester.scrollUntilVisible(
      find.text("What's new"),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("What's new"));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.0'), findsOneWidget);
  });
}
