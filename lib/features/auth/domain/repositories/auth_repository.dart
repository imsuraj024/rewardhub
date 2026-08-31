import 'package:rewardhub/features/auth/data/models/login_response_model.dart';
import 'package:rewardhub/features/auth/data/models/otp_response_model.dart';
import 'package:rewardhub/features/auth/data/models/register_response_model.dart';

/// Domain contract for authentication and session management.
///
/// Implemented in the data layer by combining a remote and a local data
/// source. Use cases depend on this abstraction, never on the implementation.
abstract interface class AuthRepository {
  Future<LoginResponseModel> login(String phone);

  Future<RegisterResponseModel> register({
    required String name,
    required String phone,
    String? referralCode,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? bankAddress,
    String? upiId,
    String? selfiePhotoPath,
    String? aadharPhotoPath,
  });

  Future<OtpResponseModel> verifyOtp({
    required String token,
    required String otp,
  });

  /// Persists the authenticated session token locally.
  Future<void> saveSession(String token);

  /// Clears any persisted session.
  Future<void> clearSession();

  /// Returns the persisted token, or `null` if there is no active session.
  Future<String?> restoreSession();

  /// Deletes the current user account remotely and clears session state.
  Future<void> deleteAccount(String token);
}
