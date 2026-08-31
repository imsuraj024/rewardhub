import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:rewardhub/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:rewardhub/features/profile/domain/repositories/profile_repository.dart';
import 'package:rewardhub/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';

/// Wires the profile module's data → domain → presentation dependencies.
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileRemoteDataSource>(() => ProfileRemoteDataSourceImpl());
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepositoryImpl(remoteDataSource: Get.find()),
    );
    Get.lazyPut(() => GetProfileUseCase(Get.find()));
    Get.lazyPut(
      () => ProfileController(
        authController: Get.find<AuthController>(),
        getProfile: Get.find(),
        analytics: Get.find<AppAnalytics>(),
      ),
    );
  }
}
