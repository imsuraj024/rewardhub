import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/network/api_endpoints.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';

/// Fetches the user profile from the network.
abstract interface class ProfileRemoteDataSource {
  Future<ProfileModel> fetchProfile({required String token});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<ProfileModel> fetchProfile({required String token}) async {
    final data = await _apiClient.post(
      ApiEndpoints.userProfile,
      data: {'token': token},
    );
    return ProfileModel.fromJson(data as Map<String, dynamic>);
  }
}
