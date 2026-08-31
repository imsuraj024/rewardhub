import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/routes/app_pages.dart';
import 'package:rewardhub/core/routes/app_routes.dart';

void main() {
  const routeNames = <String>[
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.registerAccount,
    AppRoutes.registerKyc,
    AppRoutes.otp,
    AppRoutes.shell,
    AppRoutes.home,
    AppRoutes.qrScan,
    AppRoutes.transactions,
    AppRoutes.profile,
    AppRoutes.faq,
    AppRoutes.maintenance,
    AppRoutes.appUpdate,
    AppRoutes.catalogue,
  ];

  group('AppRoutes', () {
    test('positive: every route constant is non-empty', () {
      for (final name in routeNames) {
        expect(name, isNotEmpty);
      }
    });

    test('positive: every route constant is unique', () {
      expect(routeNames.toSet().length, routeNames.length);
    });

    test('edge: every route starts with a leading slash', () {
      for (final name in routeNames) {
        expect(name.startsWith('/'), isTrue, reason: name);
      }
    });

    test('edge: splash is the root route', () {
      expect(AppRoutes.splash, '/');
    });
  });

  group('AppPages', () {
    test('positive: pages table is non-empty', () {
      expect(AppPages.pages, isNotEmpty);
    });

    test('positive: page route names are unique', () {
      final names = AppPages.pages.map((p) => p.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('positive: every page name is a declared AppRoutes constant', () {
      for (final page in AppPages.pages) {
        expect(routeNames, contains(page.name), reason: page.name);
      }
    });

    test('positive: initial route AppRoutes.splash is declared in pages', () {
      final names = AppPages.pages.map((p) => p.name).toSet();
      expect(names, contains(AppRoutes.splash));
    });

    test('edge: every page provides a page builder', () {
      for (final page in AppPages.pages) {
        expect(page.page, isNotNull);
      }
    });
  });
}
