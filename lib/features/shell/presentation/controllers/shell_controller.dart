import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/services/shorebird_update_service.dart';

import 'package:rewardhub/features/catalogue/presentation/controllers/catalogue_controller.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';

/// The bottom-navigation tabs in display order.
///
/// The enum index is the tab index used by [MainShell]'s NavigationBar and
/// IndexedStack, keeping a single source of truth for ordering.
enum ShellTab { home, catalogue, qrScan, wallet, profile }

/// Owns the active bottom-nav tab index for `MainShell`.
///
/// Any widget can `Get.find<ShellController>()` to read or change the tab.
class ShellController extends GetxController {
  ShellController(this._analytics);

  final AppAnalytics _analytics;

  /// Reactive active tab index. Kept as an [int] observable so collaborators
  /// (e.g. the QR scanner) can react to tab changes directly.
  final currentIndex = ShellTab.home.index.obs;

  ShellTab get currentTab => ShellTab.values[currentIndex.value];

  /// Selects [index] and refreshes that tab's data.
  ///
  /// Routing every selection through here (NavigationBar + Home quick actions
  /// both call it) means the tab's APIs fire on every visit — including
  /// re-tapping the tab you're already on — since the IndexedStack keeps tabs
  /// alive and wouldn't otherwise re-fetch.
  void goToTab(int index) {
    currentIndex.value = index;
    // Only a real selection counts as a click; the initial tab is reported as
    // a screen view by [_onTabShown] but not as a tap.
    _analytics.tabSelected(_analyticsName(ShellTab.values[index]));
    _onTabShown(ShellTab.values[index]);
  }

  @override
  void onReady() {
    super.onReady();
    // The shell is only reached after authentication — refresh the initial tab.
    _onTabShown(currentTab);
    _checkForUpdates();
  }

  void _onTabShown(ShellTab tab) {
    // The tabs live in an IndexedStack behind the single `/shell` route, so the
    // navigator observer never sees them — report the screen view here.
    _analytics.screenView('shell_${_analyticsName(tab)}');

    switch (tab) {
      case ShellTab.home:
        _refreshProfile();
        _refreshHomeActivities();
      case ShellTab.catalogue:
        _refreshCatalogue();
      case ShellTab.wallet:
        _refreshProfile();
        _refreshHomeActivities();
      case ShellTab.profile:
        _refreshProfile();
      case ShellTab.qrScan:
        break;
    }
  }

  /// Stable snake_case names for GA4, independent of the Dart constant names.
  static String _analyticsName(ShellTab tab) => switch (tab) {
        ShellTab.home => 'home',
        ShellTab.catalogue => 'catalogue',
        ShellTab.qrScan => 'qr_scan',
        ShellTab.wallet => 'wallet',
        ShellTab.profile => 'profile',
      };

  void _refreshCatalogue() {
    if (Get.isRegistered<CatalogueController>()) {
      Get.find<CatalogueController>().loadPdf();
    }
  }

  void _refreshProfile() {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().loadProfile();
    }
  }

  void _refreshHomeActivities() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().loadActivities();
    }
  }

  void _checkForUpdates() {
    if (Get.isRegistered<ShorebirdUpdateService>()) {
      Get.find<ShorebirdUpdateService>().checkForUpdates(isManual: false);
    }
  }
}
