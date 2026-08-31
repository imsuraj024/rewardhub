class ApiEndpoints {
  static const String baseUrl = 'http://94.103.163.118:5000';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register-new';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String deleteAccount = '/auth/delete-accountNew';

  // QR scan
  static const String qrScan = '/auth/qrscan';

  // User
  static const String userProfile = '/user/profilewithBankDetails';

  // Transactions / recent activity
  static const String transactions = '/transactions_New';

  // Wallet
  static const String raiseWalletRequest = '/wallet/raise-request';
}
