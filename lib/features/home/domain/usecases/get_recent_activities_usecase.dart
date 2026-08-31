import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/domain/repositories/home_repository.dart';

/// Returns the recent activity entries shown on the home dashboard.
///
/// Takes the session token as its parameter.
class GetRecentActivitiesUseCase
    implements UseCase<List<RecentActivityModel>, String> {
  const GetRecentActivitiesUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Future<List<RecentActivityModel>> call(String token) =>
      _repository.getRecentActivities(token: token);
}
