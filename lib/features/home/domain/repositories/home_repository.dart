import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';

/// Domain contract for the home dashboard data.
abstract interface class HomeRepository {
  Future<List<RecentActivityModel>> getRecentActivities({
    required String token,
  });
}
