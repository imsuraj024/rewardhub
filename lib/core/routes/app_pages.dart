import 'package:get/get.dart';

import 'package:rewardhub/core/routes/app_routes.dart';
import 'package:rewardhub/features/app_update/presentation/views/app_update_view.dart';
import 'package:rewardhub/features/auth/presentation/bindings/auth_binding.dart';
import 'package:rewardhub/features/auth/presentation/views/account_details_view.dart';
import 'package:rewardhub/features/auth/presentation/views/kyc_view.dart';
import 'package:rewardhub/features/auth/presentation/views/login_view.dart';
import 'package:rewardhub/features/auth/presentation/views/otp_view.dart';
import 'package:rewardhub/features/auth/presentation/views/personal_details_view.dart';
import 'package:rewardhub/features/catalogue/presentation/bindings/catalogue_binding.dart';
import 'package:rewardhub/features/catalogue/presentation/views/catalogue_view.dart';
import 'package:rewardhub/features/faq/presentation/views/faq_view.dart';
import 'package:rewardhub/features/maintenance/presentation/views/maintenance_view.dart';
import 'package:rewardhub/features/shell/presentation/bindings/shell_binding.dart';
import 'package:rewardhub/features/shell/presentation/views/main_shell.dart';
import 'package:rewardhub/features/splash/presentation/views/splash_view.dart';

/// GetX route table for the entire app.
abstract class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const PersonalDetailsView(),
      binding: PersonalDetailsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.registerAccount,
      page: () => const AccountDetailsView(),
      binding: AccountDetailsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.registerKyc,
      page: () => const KycView(),
      binding: KycBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpView(),
      binding: OtpBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.shell,
      page: () => const MainShell(),
      binding: ShellBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.faq,
      page: () => const FaqView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.maintenance,
      page: () => const MaintenanceView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.appUpdate,
      page: () => const AppUpdateView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.catalogue,
      page: () => const CatalogueView(),
      binding: CatalogueBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
