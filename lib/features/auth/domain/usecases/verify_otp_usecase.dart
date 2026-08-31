import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';

/// Input for [VerifyOtpUseCase].
class VerifyOtpParams {
  const VerifyOtpParams({required this.token, required this.otp});

  final String token;
  final String otp;
}

/// Verifies the OTP and, on success, persists the session token.
class VerifyOtpUseCase implements UseCase<void, VerifyOtpParams> {
  const VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(VerifyOtpParams params) async {
    await _repository.verifyOtp(token: params.token, otp: params.otp);
    await _repository.saveSession(params.token);
  }
}
