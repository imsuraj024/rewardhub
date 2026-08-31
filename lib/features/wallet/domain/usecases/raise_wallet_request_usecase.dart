import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/wallet/data/models/raise_request_response_model.dart';
import 'package:rewardhub/features/wallet/domain/repositories/wallet_repository.dart';

/// Raises a wallet redemption request for the current session.
///
/// Takes the session token as its parameter.
class RaiseWalletRequestUseCase
    implements UseCase<RaiseRequestResponseModel, String> {
  const RaiseWalletRequestUseCase(this._repository);

  final WalletRepository _repository;

  @override
  Future<RaiseRequestResponseModel> call(String token) =>
      _repository.raiseRequest(token: token);
}
