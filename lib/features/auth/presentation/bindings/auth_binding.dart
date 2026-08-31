import 'package:get/get.dart';

import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';
import 'package:rewardhub/features/auth/presentation/controllers/account_details_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/kyc_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/login_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/otp_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/personal_details_controller.dart';

/// Provides [LoginController] for the login route.
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LoginController(
        Get.find<AuthController>(),
        Get.find<AppAnalytics>(),
      ),
    );
  }
}

/// Provides [PersonalDetailsController] for registration step 1.
class PersonalDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PersonalDetailsController(
        Get.find<RegistrationDraftStore>(),
        Get.find<AppAnalytics>(),
      ),
    );
  }
}

/// Provides [AccountDetailsController] for registration step 2.
class AccountDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AccountDetailsController(
        Get.find<RegistrationDraftStore>(),
        Get.find<AppAnalytics>(),
      ),
    );
  }
}

/// Provides [KycController] for registration step 3.
class KycBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => KycController(
        Get.find<RegistrationDraftStore>(),
        Get.find<AuthController>(),
        Get.find<AppAnalytics>(),
      ),
    );
  }
}

/// Provides [OtpController] for the OTP route, seeded with the phone number
/// passed as a route parameter.
class OtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => OtpController(
        phone: Get.parameters['phone'] ?? '',
        auth: Get.find<AuthController>(),
        analytics: Get.find<AppAnalytics>(),
      ),
    );
  }
}
