import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/services/push_notification_service.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:rewardhub/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';
import 'package:rewardhub/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardhub/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/login_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/logout_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/register_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:rewardhub/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';

/// Root binding registered once via `GetMaterialApp.initialBinding`.
///
/// Wires the authentication stack as permanent singletons so the session and
/// [AuthController] are available to every feature throughout the app's life.
class InitialBinding extends Bindings {
  InitialBinding({
    required this.analytics,
    this.remoteConfigService,
    this.pushNotificationService,
  });

  /// Created in `main()` (it needs an initialised Firebase) and registered here
  /// so every feature binding can resolve the same instance.
  final AppAnalytics analytics;

  /// Remote config service initialized on startup.
  final RemoteConfigService? remoteConfigService;

  /// Push notification service initialized on startup.
  final PushNotificationService? pushNotificationService;

  @override
  void dependencies() {
    Get.put<AppAnalytics>(analytics, permanent: true);
    Get.put<ShorebirdUpdateService>(ShorebirdUpdateService(), permanent: true);
    Get.put<RemoteConfigService>(
      remoteConfigService ?? RemoteConfigService(),
      permanent: true,
    );
    Get.put<PushNotificationService>(
      pushNotificationService ?? PushNotificationService(),
      permanent: true,
    );

    // Data sources
    Get.put<AuthRemoteDataSource>(AuthRemoteDataSourceImpl(), permanent: true);
    Get.put<AuthLocalDataSource>(AuthLocalDataSourceImpl(), permanent: true);
    Get.put<RegistrationDraftStore>(
      RegistrationDraftStoreImpl(),
      permanent: true,
    );

    // Repository
    Get.put<AuthRepository>(
      AuthRepositoryImpl(
        remoteDataSource: Get.find(),
        localDataSource: Get.find(),
      ),
      permanent: true,
    );

    // Use cases
    Get.put(LoginUseCase(Get.find()), permanent: true);
    Get.put(RegisterUseCase(Get.find()), permanent: true);
    Get.put(VerifyOtpUseCase(Get.find()), permanent: true);
    Get.put(RestoreSessionUseCase(Get.find()), permanent: true);
    Get.put(LogoutUseCase(Get.find()), permanent: true);
    Get.put(DeleteAccountUseCase(Get.find()), permanent: true);

    // Controller
    final authController = Get.put(
      AuthController(
        loginUseCase: Get.find(),
        registerUseCase: Get.find(),
        verifyOtpUseCase: Get.find(),
        restoreSessionUseCase: Get.find(),
        logoutUseCase: Get.find(),
        deleteAccountUseCase: Get.find<DeleteAccountUseCase>(),
        analytics: analytics,
      ),
      permanent: true,
    );

    // A token the server rejects has to bounce the user back to login.
    // AuthInterceptor drops the stored token on a 401 but cannot navigate, so
    // it calls back through here. Wired in this binding because it is the one
    // place that runs once, before any screen can issue a request — leaving it
    // unregistered means an expired session fails every call in silence.
    ApiClient().setUnauthenticatedHandler(authController.handleSessionExpired);
  }
}
