import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/features/catalogue/presentation/bindings/catalogue_binding.dart';
import 'package:rewardhub/features/home/presentation/bindings/home_binding.dart';
import 'package:rewardhub/features/profile/presentation/bindings/profile_binding.dart';
import 'package:rewardhub/features/qr_scan/presentation/bindings/qr_scan_binding.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';
import 'package:rewardhub/features/wallet/presentation/bindings/wallet_binding.dart';

/// Wires the shell and every tab it hosts.
///
/// The shell shows all tabs in a single [IndexedStack], so each tab's
/// dependencies are registered up front by composing the module bindings.
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ShellController(Get.find<AppAnalytics>()));
    ProfileBinding().dependencies();
    HomeBinding().dependencies();
    CatalogueBinding().dependencies();
    QrScanBinding().dependencies();
    WalletBinding().dependencies();
  }
}
