import 'package:rewardhub/core/analytics/app_analytics.dart';
import 'package:rewardhub/core/analytics/i_analytics_service.dart';

/// One call recorded by [RecordingAnalyticsService].
///
/// [name] is the wire event name (`login`, `qr_scan_succeeded`, ...) and
/// [parameters] the payload exactly as it would reach Firebase, so tests pin
/// the real contract rather than "some method was called".
class AnalyticsCall {
  const AnalyticsCall(this.name, [this.parameters = const {}]);

  final String name;
  final Map<String, Object> parameters;

  @override
  String toString() => 'AnalyticsCall($name, $parameters)';
}

/// In-memory [IAnalyticsService] that records instead of sending.
///
/// Reserved events are normalised to the names and parameters Firebase would
/// receive (`login` with `method`, `screen_view` with `screen_name`, ...) so a
/// test asserting on `login` is asserting on what GA4 actually gets.
class RecordingAnalyticsService implements IAnalyticsService {
  final List<AnalyticsCall> calls = <AnalyticsCall>[];
  final List<String?> userIds = <String?>[];
  final Map<String, String?> userProperties = <String, String?>{};

  bool? collectionEnabled;
  int resetCount = 0;

  /// Every recorded event name, in order.
  List<String> get names => calls.map((c) => c.name).toList();

  /// The single recorded call, failing loudly if there is not exactly one.
  AnalyticsCall get single => calls.single;

  /// The first recorded call named [name], or null.
  AnalyticsCall? call(String name) =>
      calls.where((c) => c.name == name).firstOrNull;

  /// Every parameter value ever recorded, flattened — used to assert that no
  /// personal data leaked into any event.
  Iterable<Object> get allParameterValues =>
      calls.expand((c) => c.parameters.values);

  void clear() {
    calls.clear();
    userIds.clear();
    userProperties.clear();
    resetCount = 0;
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      collectionEnabled = enabled;

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async =>
      calls.add(AnalyticsCall(name, parameters ?? const {}));

  @override
  Future<void> logScreenView({required String screenName}) async =>
      calls.add(AnalyticsCall('screen_view', {'screen_name': screenName}));

  @override
  Future<void> logLogin({required String method}) async =>
      calls.add(AnalyticsCall('login', {'method': method}));

  @override
  Future<void> logSignUp({required String method}) async =>
      calls.add(AnalyticsCall('sign_up', {'method': method}));

  @override
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) async =>
      calls.add(AnalyticsCall('select_content', {
        'content_type': contentType,
        'item_id': itemId,
      }));

  @override
  Future<void> setUserId(String? userId) async => userIds.add(userId);

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async =>
      userProperties[name] = value;

  @override
  Future<void> reset() async => resetCount++;
}

/// A [RecordingAnalyticsService] paired with the [AppAnalytics] facade over it,
/// which is what controllers take.
class AnalyticsHarness {
  AnalyticsHarness() : service = RecordingAnalyticsService() {
    analytics = AppAnalytics(service);
  }

  final RecordingAnalyticsService service;
  late final AppAnalytics analytics;

  List<AnalyticsCall> get calls => service.calls;
  List<String> get names => service.names;
  AnalyticsCall? call(String name) => service.call(name);
}
