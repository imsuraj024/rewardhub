/// Route name constants used across the app instead of string literals.
///
/// These are consumed by [AppPages] and by GetX navigation calls
/// (`Get.toNamed`, `Get.offAllNamed`, ...).
abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const registerAccount = '/register/account';
  static const registerKyc = '/register/kyc';
  static const otp = '/otp';
  static const shell = '/shell';
  static const home = '/shell/home';
  static const qrScan = '/shell/qr-scan';
  static const transactions = '/shell/transactions';
  static const profile = '/shell/profile';
  static const faq = '/faq';
  static const maintenance = '/maintenance';
  static const appUpdate = '/app-update';
  static const catalogue = '/catalogue';
}
