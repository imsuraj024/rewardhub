import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/network/api_endpoints.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';

abstract interface class HomeRemoteDataSource {
  Future<List<RecentActivityModel>> getRecentActivities({
    required String token,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<RecentActivityModel>> getRecentActivities({
    required String token,
  }) async {
    final data = await _apiClient.post(
      ApiEndpoints.transactions,
      data: {'token': token},
    );
    final list = (data as Map<String, dynamic>)['transactions'] as List? ?? [];
    return list
        .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
