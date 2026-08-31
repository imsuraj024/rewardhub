import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/logger.dart';

/// Top-level background message handler required by Firebase Cloud Messaging.
/// Must be annotated with `@pragma('vm:entry-point')` so it isn't tree-shaken in release mode.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log(
    'Background message received: ${message.messageId} | ${message.notification?.title}',
    name: 'rewardhub.push_notification',
  );
}

/// Service managing Firebase Cloud Messaging (FCM) permissions, tokens, and notification streams.
class PushNotificationService extends GetxService {
  PushNotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging;

  FirebaseMessaging? _messaging;

  /// Lazy getter for [FirebaseMessaging].
  FirebaseMessaging get messaging => _messaging ??= FirebaseMessaging.instance;

  /// Reactive FCM registration token.
  final RxnString fcmToken = RxnString();

  /// Notification authorization status.
  final Rx<AuthorizationStatus> authorizationStatus = Rx<AuthorizationStatus>(
    AuthorizationStatus.notDetermined,
  );

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  /// Initializes FCM: requests permission, retrieves initial FCM token, and sets up listeners.
  Future<void> initialize() async {
    try {
      await requestPermission();
      await fetchFcmToken();
      _listenToTokenRefresh();
      _listenToForegroundMessages();
      _listenToMessageOpenedApp();
      await handleInitialMessage();
    } catch (e, st) {
      log(
        'PushNotificationService initialization failed',
        name: 'rewardhub.push_notification',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Requests notification permissions on iOS, Web, and Android 13+.
  Future<AuthorizationStatus> requestPermission() async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      authorizationStatus.value = settings.authorizationStatus;
      log(
        'FCM Permission status: ${settings.authorizationStatus}',
        name: 'rewardhub.push_notification',
      );
      return settings.authorizationStatus;
    } catch (e, st) {
      log(
        'Failed to request FCM permission',
        name: 'rewardhub.push_notification',
        error: e,
        stackTrace: st,
      );
      return AuthorizationStatus.denied;
    }
  }

  /// Fetches current FCM registration token.
  Future<String?> fetchFcmToken() async {
    try {
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        fcmToken.value = token;
        log('FCM Token retrieved: $token', name: 'rewardhub.push_notification');
      }
      return token;
    } catch (e, st) {
      log(
        'Failed to fetch FCM token',
        name: 'rewardhub.push_notification',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  void _listenToTokenRefresh() {
    _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
      fcmToken.value = newToken;
      log(
        'FCM Token refreshed: $newToken',
        name: 'rewardhub.push_notification',
      );
    });
  }

  void _listenToForegroundMessages() {
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      log(
        'Foreground FCM message received: ${message.notification?.title}',
        name: 'rewardhub.push_notification',
      );
      final notification = message.notification;
      if (notification != null) {
        final title = notification.title;
        final body = notification.body;
        if (body != null && body.isNotEmpty) {
          AppToast.info(body, title: title);
        }
      }
    });
  }

  void _listenToMessageOpenedApp() {
    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      log(
        'FCM Notification tapped (onMessageOpenedApp): ${message.messageId}',
        name: 'rewardhub.push_notification',
      );
      _handleNotificationClick(message);
    });
  }

  /// Handles cold-start notification tap if the app was launched from a notification.
  Future<void> handleInitialMessage() async {
    try {
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        log(
          'Cold-start FCM Notification tapped: ${initialMessage.messageId}',
          name: 'rewardhub.push_notification',
        );
        _handleNotificationClick(initialMessage);
      }
    } catch (e, st) {
      log(
        'Error retrieving initial FCM message',
        name: 'rewardhub.push_notification',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      Get.toNamed(route);
    }
  }

  @override
  void onClose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
    super.onClose();
  }
}
