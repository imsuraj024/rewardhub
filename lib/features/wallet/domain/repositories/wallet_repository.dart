import 'package:rewardhub/features/wallet/data/models/raise_request_response_model.dart';

/// Domain contract for wallet actions.
abstract interface class WalletRepository {
  Future<RaiseRequestResponseModel> raiseRequest({required String token});
}
