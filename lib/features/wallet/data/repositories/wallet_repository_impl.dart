import 'package:rewardhub/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:rewardhub/features/wallet/data/models/raise_request_response_model.dart';
import 'package:rewardhub/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({required WalletRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final WalletRemoteDataSource _remote;

  @override
  Future<RaiseRequestResponseModel> raiseRequest({required String token}) =>
      _remote.raiseRequest(token: token);
}
