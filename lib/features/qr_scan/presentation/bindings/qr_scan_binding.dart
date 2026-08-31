import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/qr_scan/data/datasources/qr_scan_remote_data_source.dart';
import 'package:rewardhub/features/qr_scan/data/repositories/qr_scan_repository_impl.dart';
import 'package:rewardhub/features/qr_scan/domain/repositories/qr_scan_repository.dart';
import 'package:rewardhub/features/qr_scan/domain/usecases/submit_qr_scan_usecase.dart';
import 'package:rewardhub/features/qr_scan/presentation/controllers/qr_scan_controller.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';

/// Wires the QR scan module's data → domain → presentation dependencies.
class QrScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QrScanRemoteDataSource>(() => QrScanRemoteDataSourceImpl());
    Get.lazyPut<QrScanRepository>(
      () => QrScanRepositoryImpl(remoteDataSource: Get.find()),
    );
    Get.lazyPut(() => SubmitQrScanUseCase(Get.find()));
    Get.lazyPut(
      () => QrScanController(
        submitQrScan: Get.find(),
        authController: Get.find<AuthController>(),
        shellController: Get.find<ShellController>(),
        analytics: Get.find<AppAnalytics>(),
      ),
    );
  }
}
