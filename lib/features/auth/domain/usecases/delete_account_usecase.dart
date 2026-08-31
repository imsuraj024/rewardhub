import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';

/// Deletes the current user account remotely and clears session state.
class DeleteAccountUseCase implements UseCase<void, String> {
  const DeleteAccountUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(String params) => _repository.deleteAccount(params);
}
