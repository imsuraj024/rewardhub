/// Transport for analytics.
///
/// Deliberately thin and vendor-neutral: it knows how to *send* an event but
/// nothing about this app's events. The taxonomy lives in `AppAnalytics`, so
/// swapping Firebase for another backend means writing one new implementation
/// of this interface and touching no call sites.
///
/// Implementations must never throw: analytics is fire-and-forget telemetry and
/// must not be able to break a user flow.
abstract interface class IAnalyticsService {
  /// Turns collection on or off. Off means nothing is recorded or queued.
  Future<void> setCollectionEnabled(bool enabled);

  /// Records a custom event.
  ///
  /// [name] must be snake_case, and [parameters] values must already be
  /// within GA4's limits — `AppAnalytics` is responsible for enforcing that.
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);

  /// Records a screen view.
  Future<void> logScreenView({required String screenName});

  /// Records the reserved `login` event.
  Future<void> logLogin({required String method});

  /// Records the reserved `sign_up` event.
  Future<void> logSignUp({required String method});

  /// Records the reserved `select_content` event, used for taps on named UI.
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  });

  /// Associates subsequent events with [userId], or clears it when null.
  ///
  /// [userId] must be a pseudonymous identifier — never a phone number, name
  /// or any other direct identifier.
  Future<void> setUserId(String? userId);

  /// Sets a user property used for segmentation. A null [value] clears it.
  Future<void> setUserProperty({required String name, required String? value});

  /// Drops all locally collected data and the current identity.
  Future<void> reset();
}
