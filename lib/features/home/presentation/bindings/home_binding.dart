import 'package:get/get.dart';

import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/home/data/datasources/home_remote_data_source.dart';
import 'package:rewardhub/features/home/data/repositories/home_repository_impl.dart';
import 'package:rewardhub/features/home/domain/repositories/home_repository.dart';
import 'package:rewardhub/features/home/domain/usecases/get_recent_activities_usecase.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';

/// Wires the home module's data → domain → presentation dependencies.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeRemoteDataSource>(() => HomeRemoteDataSourceImpl());
    Get.lazyPut<HomeRepository>(
      () => HomeRepositoryImpl(remoteDataSource: Get.find()),
    );
    Get.lazyPut(() => GetRecentActivitiesUseCase(Get.find()));
    Get.lazyPut(
      () => HomeController(
        authController: Get.find<AuthController>(),
        getRecentActivities: Get.find(),
      ),
    );
  }
}
