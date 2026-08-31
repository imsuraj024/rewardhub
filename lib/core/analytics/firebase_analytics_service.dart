import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

import 'package:rewardhub/core/analytics/i_analytics_service.dart';
import 'package:rewardhub/core/utils/logger.dart';

/// Whether analytics collection should be on for this build.
///
/// Off in debug so development taps never pollute the production property —
/// otherwise every hot restart inflates the funnel. Pass
/// `--dart-define=analytics=true` to switch it on locally when you need to
/// verify events in Firebase's DebugView.
const bool analyticsEnabled = !kDebugMode || bool.hasEnvironment('analytics');

/// [IAnalyticsService] backed by Firebase Analytics (GA4).
///
/// Every call is wrapped in a try/catch and awaited nowhere the user can feel
/// it: a telemetry failure must never surface as a broken button. Failures are
/// logged in debug builds only.
class FirebaseAnalyticsService implements IAnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// The observer that turns route pushes into `screen_view` events.
  ///
  /// Passed to `GetMaterialApp.navigatorObservers`. GetX appends its own
  /// `GetObserver` alongside it, so its routing keeps working.
  ///
  /// Created once and cached: `build()` can run many times, and handing the
  /// Navigator a fresh observer each time would double-report screen views.
  late final NavigatorObserver navigatorObserver = FirebaseAnalyticsObserver(
    analytics: _analytics,
    nameExtractor: _screenNameFromRoute,
  );

  /// Turns GetX's path-style route names into readable screen names, so GA4
  /// shows `login` / `register_kyc` rather than `/login` / `/register/kyc`.
  static String? _screenNameFromRoute(RouteSettings settings) {
    final name = settings.name;
    if (name == null || name.isEmpty) return null;
    if (name == '/') return 'splash';
    return name.replaceFirst('/', '').replaceAll('/', '_').replaceAll('-', '_');
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _guard('setCollectionEnabled',
          () => _analytics.setAnalyticsCollectionEnabled(enabled));

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) =>
      _guard(
        'logEvent($name)',
        () => _analytics.logEvent(
          name: name,
          parameters: parameters == null || parameters.isEmpty
              ? null
              : parameters,
        ),
      );

  @override
  Future<void> logScreenView({required String screenName}) => _guard(
        'logScreenView($screenName)',
        () => _analytics.logScreenView(screenName: screenName),
      );

  @override
  Future<void> logLogin({required String method}) =>
      _guard('logLogin', () => _analytics.logLogin(loginMethod: method));

  @override
  Future<void> logSignUp({required String method}) =>
      _guard('logSignUp', () => _analytics.logSignUp(signUpMethod: method));

  @override
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) =>
      _guard(
        'logSelectContent($itemId)',
        () => _analytics.logSelectContent(
          contentType: contentType,
          itemId: itemId,
        ),
      );

  @override
  Future<void> setUserId(String? userId) =>
      _guard('setUserId', () => _analytics.setUserId(id: userId));

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) =>
      _guard(
        'setUserProperty($name)',
        () => _analytics.setUserProperty(name: name, value: value),
      );

  @override
  Future<void> reset() => _guard('reset', _analytics.resetAnalyticsData);

  /// Swallows every analytics failure. Telemetry is never worth an exception in
  /// a user flow, and Crashlytics already covers genuine crashes.
  Future<void> _guard(String action, Future<void> Function() body) async {
    try {
      await body();
    } catch (e, st) {
      if (kDebugMode) {
        log(
          'analytics $action failed',
          name: 'rewardhub.analytics',
          error: e,
          stackTrace: st,
        );
      }
    }
  }
}
