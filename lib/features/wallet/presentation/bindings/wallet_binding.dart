import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:rewardhub/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:rewardhub/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:rewardhub/features/wallet/domain/usecases/raise_wallet_request_usecase.dart';
import 'package:rewardhub/features/wallet/presentation/controllers/wallet_controller.dart';

/// Wires the wallet module's data → domain → presentation dependencies.
class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletRemoteDataSource>(() => WalletRemoteDataSourceImpl());
    Get.lazyPut<WalletRepository>(
      () => WalletRepositoryImpl(remoteDataSource: Get.find()),
    );
    Get.lazyPut(() => RaiseWalletRequestUseCase(Get.find()));
    Get.lazyPut(
      () => WalletController(
        authController: Get.find<AuthController>(),
        raiseWalletRequest: Get.find(),
        analytics: Get.find<AppAnalytics>(),
      ),
    );
  }
}
