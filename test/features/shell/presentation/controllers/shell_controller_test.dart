import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rewardhub/features/catalogue/presentation/controllers/catalogue_controller.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

/// Spies for the tab controllers `ShellController` refreshes.
///
/// These deliberately **extend `GetxController`** instead of being mocktail
/// mocks. `Get.put` runs the GetX lifecycle on whatever it registers, reading
/// `onStart` — an `InternalFinalCallback` field, not a method. A mock returns
/// `null` for it, so registering a mocked controller dies with
/// "type 'Null' is not a subtype of type 'InternalFinalCallback'".
/// Extending the real base class gives us a genuine lifecycle; the declared
/// `noSuchMethod` makes Dart generate throwing stubs for the rest of the
/// interface, so any call the shell is not supposed to make fails loudly.
class _SpyProfileController extends GetxController
    implements ProfileController {
  int loadProfileCalls = 0;

  @override
  Future<void> loadProfile({bool force = false}) async {
    loadProfileCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyHomeController extends GetxController implements HomeController {
  int loadActivitiesCalls = 0;

  @override
  Future<void> loadActivities() async {
    loadActivitiesCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyCatalogueController extends GetxController
    implements CatalogueController {
  int loadPdfCalls = 0;

  @override
  Future<void> loadPdf({bool forceRefresh = false}) async {
    loadPdfCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AnalyticsHarness analytics;
  setUp(() {
    analytics = AnalyticsHarness();
    installGetTestHarness();
  });

  tearDown(resetGet);

  group('currentTab', () {
    test('positive: defaults to the home tab', () {
      final c = ShellController(analytics.analytics);
      expect(c.currentIndex.value, ShellTab.home.index);
      expect(c.currentTab, ShellTab.home);
    });

    test('positive: reflects the active index', () {
      final c = ShellController(analytics.analytics);
      c.currentIndex.value = ShellTab.profile.index;
      expect(c.currentTab, ShellTab.profile);
    });
  });

  group('goToTab', () {
    test('positive: switches to the qr tab (no data refresh wired)', () {
      final c = ShellController(analytics.analytics);

      c.goToTab(ShellTab.qrScan.index);

      expect(c.currentIndex.value, ShellTab.qrScan.index);
      expect(c.currentTab, ShellTab.qrScan);
    });

    test('positive: home tab refreshes both profile and activities', () {
      final profile = _SpyProfileController();
      final home = _SpyHomeController();
      Get.put<ProfileController>(profile);
      Get.put<HomeController>(home);
      final c = ShellController(analytics.analytics);

      c.goToTab(ShellTab.home.index);

      expect(profile.loadProfileCalls, 1);
      expect(home.loadActivitiesCalls, 1);
    });

    test('positive: catalogue tab refreshes the catalogue pdf', () {
      final catalogue = _SpyCatalogueController();
      Get.put<CatalogueController>(catalogue);
      final c = ShellController(analytics.analytics);

      c.goToTab(ShellTab.catalogue.index);

      expect(catalogue.loadPdfCalls, 1);
    });

    test('positive: profile tab refreshes only the profile', () {
      final profile = _SpyProfileController();
      final home = _SpyHomeController();
      Get.put<ProfileController>(profile);
      Get.put<HomeController>(home);
      final c = ShellController(analytics.analytics);

      c.goToTab(ShellTab.profile.index);

      expect(profile.loadProfileCalls, 1);
      expect(home.loadActivitiesCalls, 0);
    });

    test('edge: no registered controllers -> no throw', () {
      final c = ShellController(analytics.analytics);
      expect(() => c.goToTab(ShellTab.home.index), returnsNormally);
      expect(() => c.goToTab(ShellTab.catalogue.index), returnsNormally);
      expect(() => c.goToTab(ShellTab.profile.index), returnsNormally);
    });

    test('edge: re-tapping the current tab still refreshes it', () {
      final profile = _SpyProfileController();
      Get.put<ProfileController>(profile);
      final c = ShellController(analytics.analytics);

      c.goToTab(ShellTab.profile.index);
      c.goToTab(ShellTab.profile.index);

      expect(profile.loadProfileCalls, 2);
    });
  });

  group('onReady', () {
    test('positive: refreshes the initial (home) tab', () {
      final profile = _SpyProfileController();
      final home = _SpyHomeController();
      Get.put<ProfileController>(profile);
      Get.put<HomeController>(home);
      final c = ShellController(analytics.analytics);

      c.onReady();

      expect(profile.loadProfileCalls, 1);
      expect(home.loadActivitiesCalls, 1);
    });

    test('edge: onReady with no registered controllers -> no throw', () {
      final c = ShellController(analytics.analytics);
      expect(c.onReady, returnsNormally);
    });
  });

  group('analytics', () {
    test('positive: selecting a tab reports the click and the screen', () {
      ShellController(analytics.analytics).goToTab(ShellTab.qrScan.index);

      expect(analytics.names, ['tab_selected', 'screen_view']);
      expect(analytics.call('tab_selected')!.parameters['tab_name'], 'qr_scan');
      expect(
        analytics.call('screen_view')!.parameters['screen_name'],
        'shell_qr_scan',
      );
    });

    test('positive: tab names are snake_case for every tab', () {
      final c = ShellController(analytics.analytics);
      for (final tab in ShellTab.values) {
        c.goToTab(tab.index);
      }

      final names = analytics.calls
          .where((call) => call.name == 'tab_selected')
          .map((call) => call.parameters['tab_name'])
          .toList();
      expect(names, ['home', 'catalogue', 'qr_scan', 'wallet', 'profile']);
    });

    test('negative: the initial tab is a screen view but not a click', () {
      ShellController(analytics.analytics).onReady();

      // onReady is the shell appearing, not the user tapping a tab.
      expect(analytics.names, ['screen_view']);
      expect(
        analytics.call('screen_view')!.parameters['screen_name'],
        'shell_home',
      );
    });
  });
}
