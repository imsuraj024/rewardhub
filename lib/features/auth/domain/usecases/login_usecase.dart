import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/auth/data/models/login_response_model.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';

/// Requests an OTP for the given mobile number, or reports a new user.
class LoginUseCase implements UseCase<LoginResponseModel, String> {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<LoginResponseModel> call(String phone) => _repository.login(phone);
}
