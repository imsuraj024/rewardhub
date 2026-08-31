import 'package:get/get.dart';

import 'package:rewardhub/core/utils/error_message.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/domain/usecases/get_recent_activities_usecase.dart';

/// Backs the home dashboard's recent activity feed.
///
/// The balance card is driven by the shared `ProfileController`; this
/// controller owns only the recent activity list.
class HomeController extends GetxController {
  HomeController({
    required AuthController authController,
    required GetRecentActivitiesUseCase getRecentActivities,
  }) : _auth = authController,
       _getRecentActivities = getRecentActivities;

  final AuthController _auth;
  final GetRecentActivitiesUseCase _getRecentActivities;

  final _state = Rx<ViewState<List<RecentActivityModel>>>(
    const ViewStateInitial(),
  );
  bool _inFlight = false;

  ViewState<List<RecentActivityModel>> get state => _state.value;

  @override
  void onInit() {
    super.onInit();
    // Load now if a session already exists, and again whenever the token
    // becomes available — race-free regardless of construction order.
    ever<String?>(_auth.tokenListenable, (token) {
      if (token != null && token.isNotEmpty) loadActivities();
    });
    loadActivities();
  }

  Future<void> loadActivities() async {
    if (_inFlight) return;
    final token = _auth.token;
    if (token == null) return;

    _inFlight = true;
    if (_state.value is! ViewStateSuccess) {
      _state.value = const ViewStateLoading();
    }
    try {
      final activities = await _getRecentActivities(token);
      _state.value = ViewStateSuccess(activities);
    } catch (e, st) {
      log(
        'loadActivities failed',
        name: 'rewardhub.home',
        error: e,
        stackTrace: st,
      );
      if (_state.value is! ViewStateSuccess) {
        _state.value = ViewStateError(resolveErrorMessage(e));
      }
    } finally {
      _inFlight = false;
    }
  }
}
