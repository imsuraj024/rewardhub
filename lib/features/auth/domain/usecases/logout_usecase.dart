import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';

/// Clears the persisted session, ending the current login.
class LogoutUseCase implements UseCase<void, NoParams> {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(NoParams params) => _repository.clearSession();
}
