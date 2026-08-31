import 'package:get/get.dart';
import 'package:rewardhub/features/catalogue/presentation/controllers/catalogue_controller.dart';

/// Instantiates [CatalogueController] when entering the catalogue screen.
class CatalogueBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CatalogueController>(() => CatalogueController());
  }
}
