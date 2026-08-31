import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/network/api_endpoints.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/wallet/data/models/raise_request_response_model.dart';

/// Raises wallet redemption requests against the rewards backend.
abstract interface class WalletRemoteDataSource {
  Future<RaiseRequestResponseModel> raiseRequest({required String token});
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<RaiseRequestResponseModel> raiseRequest({required String token}) async {
    final data = await _apiClient.post(
      ApiEndpoints.raiseWalletRequest,
      data: {'token': token},
    );
    final response =
        RaiseRequestResponseModel.fromJson(data as Map<String, dynamic>);
    if (!response.success) {
      throw ApiException(response.message ?? 'Could not raise your request.');
    }
    return response;
  }
}
