import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';
import 'package:rewardhub/features/wallet/domain/usecases/raise_wallet_request_usecase.dart';
import 'package:rewardhub/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:rewardhub/features/wallet/presentation/views/wallet_view.dart';

import '../../../../helpers/harness.dart';

class MockAuthController extends GetxController
    with Mock
    implements AuthController {}

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockRaiseWalletRequestUseCase extends Mock
    implements RaiseWalletRequestUseCase {}

class MockAppAnalytics extends Mock implements AppAnalytics {}

class MockShellController extends GetxController
    with Mock
    implements ShellController {}

void main() {
  late MockAuthController mockAuth;
  late MockGetProfileUseCase mockGetProfile;
  late ProfileController profileController;
  late MockRaiseWalletRequestUseCase mockRaiseRequest;
  late MockAppAnalytics mockAnalytics;
  late WalletController walletController;
  late MockShellController mockShell;

  final testProfile = ProfileModel(
    id: '1',
    name: 'Test User',
    mobile: '9876543210',
    points: 650,
  );

  setUp(() {
    installGetTestHarness();
    mockAuth = MockAuthController();
    mockGetProfile = MockGetProfileUseCase();
    mockRaiseRequest = MockRaiseWalletRequestUseCase();
    mockAnalytics = MockAppAnalytics();
    mockShell = MockShellController();

    when(() => mockAuth.token).thenReturn('token');
    when(() => mockAuth.tokenListenable).thenReturn(Rxn<String>('token'));
    when(() => mockGetProfile.call('token')).thenAnswer((_) async => testProfile);

    Get.put<AuthController>(mockAuth);

    profileController = ProfileController(
      authController: mockAuth,
      getProfile: mockGetProfile,
      analytics: mockAnalytics,
    );
    Get.put<ProfileController>(profileController);
    Get.put<ShellController>(mockShell);

    walletController = WalletController(
      authController: mockAuth,
      raiseWalletRequest: mockRaiseRequest,
      analytics: mockAnalytics,
    );
    Get.put<WalletController>(walletController);
  });

  tearDown(() async {
    await resetGet();
  });

  testWidgets('renders WalletView elements correctly', (tester) async {
    await profileController.loadProfile();
    await pumpApp(tester, const WalletView());
    await tester.pumpAndSettle();

    expect(find.text('My Wallet'), findsOneWidget);
    expect(find.text('Available Balance'), findsOneWidget);
    expect(find.text('650'), findsOneWidget);
    expect(find.text('POINTS'), findsOneWidget);
    expect(find.text('Redeem Points'), findsWidgets);
    expect(find.text('Transaction History'), findsOneWidget);
  });
}
