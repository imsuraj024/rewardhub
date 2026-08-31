import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';

/// Returns the persisted session token, or `null` when no session exists.
class RestoreSessionUseCase implements UseCase<String?, NoParams> {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<String?> call(NoParams params) => _repository.restoreSession();
}
