import 'package:rewardhub/features/home/data/datasources/home_remote_data_source.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required HomeRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final HomeRemoteDataSource _remote;

  @override
  Future<List<RecentActivityModel>> getRecentActivities({
    required String token,
  }) =>
      _remote.getRecentActivities(token: token);
}
