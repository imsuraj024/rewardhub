import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rewardhub/features/catalogue/presentation/views/catalogue_view.dart';
import 'package:rewardhub/features/home/presentation/views/home_view.dart';
import 'package:rewardhub/features/profile/presentation/views/profile_view.dart';
import 'package:rewardhub/features/qr_scan/presentation/views/qr_scan_view.dart';
import 'package:rewardhub/features/shell/presentation/controllers/shell_controller.dart';
import 'package:rewardhub/features/wallet/presentation/views/wallet_view.dart';

/// Bottom-navigation shell.
///
/// A single [_destinations] list is the source of truth for both the page shown
/// in the [IndexedStack] (which preserves each tab's state across switches) and
/// the Material 3 [NavigationBar] destinations, so the two can never drift out
/// of sync. Styling lives in `AppTheme.navigationBarTheme`.
class MainShell extends GetView<ShellController> {
  const MainShell({super.key});

  static const _destinations = <_ShellDestination>[
    _ShellDestination(
      page: HomeView(),
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _ShellDestination(
      page: CatalogueView(showBackButton: false),
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Catalogue',
    ),
    _ShellDestination(
      page: QrScanView(),
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner_rounded,
      label: 'Scan',
    ),
    _ShellDestination(
      page: WalletView(),
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      label: 'Wallet',
    ),
    _ShellDestination(
      page: ProfileView(),
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: [for (final d in _destinations) d.page],
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: controller.goToTab,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
                tooltip: d.label,
              ),
          ],
        ),
      ),
    );

    // Back on any tab other than Home returns to Home; on Home it closes the
    // app as before. The Obx encloses PopScope so canPop follows the tab, and
    // the same scaffold is reused so no tab state is lost.
    return Obx(
      () => PopScope(
        canPop: controller.currentIndex.value == ShellTab.home.index,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.returnToHome();
        },
        child: scaffold,
      ),
    );
  }
}

/// Pairs a tab's page with its [NavigationBar] presentation.
class _ShellDestination {
  const _ShellDestination({
    required this.page,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Widget page;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
