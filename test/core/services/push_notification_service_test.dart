import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/services/push_notification_service.dart';

import '../../helpers/harness.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

void main() {
  late MockFirebaseMessaging mockMessaging;
  late MockNotificationSettings mockSettings;
  late StreamController<String> tokenRefreshController;

  setUp(() {
    installGetTestHarness();
    mockMessaging = MockFirebaseMessaging();
    mockSettings = MockNotificationSettings();
    tokenRefreshController = StreamController<String>.broadcast();

    when(() => mockSettings.authorizationStatus)
        .thenReturn(AuthorizationStatus.authorized);
    when(
      () => mockMessaging.requestPermission(
        alert: any(named: 'alert'),
        announcement: any(named: 'announcement'),
        badge: any(named: 'badge'),
        carPlay: any(named: 'carPlay'),
        criticalAlert: any(named: 'criticalAlert'),
        provisional: any(named: 'provisional'),
        sound: any(named: 'sound'),
      ),
    ).thenAnswer((_) async => mockSettings);

    when(() => mockMessaging.getToken())
        .thenAnswer((_) async => 'mock-fcm-token-12345');
    when(() => mockMessaging.onTokenRefresh)
        .thenAnswer((_) => tokenRefreshController.stream);
    when(() => mockMessaging.getInitialMessage())
        .thenAnswer((_) async => null);
  });

  tearDown(() async {
    await tokenRefreshController.close();
    await resetGet();
  });

  group('PushNotificationService', () {
    test('positive: initialize requests permission and fetches FCM token',
        () async {
      final service = PushNotificationService(messaging: mockMessaging);

      await service.initialize();

      expect(service.authorizationStatus.value, AuthorizationStatus.authorized);
      expect(service.fcmToken.value, 'mock-fcm-token-12345');
    });

    test('positive: requestPermission returns authorization status', () async {
      final service = PushNotificationService(messaging: mockMessaging);

      final status = await service.requestPermission();

      expect(status, AuthorizationStatus.authorized);
      expect(service.authorizationStatus.value, AuthorizationStatus.authorized);
    });

    test('negative: requestPermission handles exceptions gracefully', () async {
      when(
        () => mockMessaging.requestPermission(
          alert: any(named: 'alert'),
          announcement: any(named: 'announcement'),
          badge: any(named: 'badge'),
          carPlay: any(named: 'carPlay'),
          criticalAlert: any(named: 'criticalAlert'),
          provisional: any(named: 'provisional'),
          sound: any(named: 'sound'),
        ),
      ).thenThrow(Exception('Permission error'));

      final service = PushNotificationService(messaging: mockMessaging);

      final status = await service.requestPermission();

      expect(status, AuthorizationStatus.denied);
    });

    test('positive: fetchFcmToken updates reactive fcmToken variable',
        () async {
      final service = PushNotificationService(messaging: mockMessaging);

      final token = await service.fetchFcmToken();

      expect(token, 'mock-fcm-token-12345');
      expect(service.fcmToken.value, 'mock-fcm-token-12345');
    });

    test('negative: fetchFcmToken returns null on failure', () async {
      when(() => mockMessaging.getToken())
          .thenThrow(Exception('Token fetch error'));

      final service = PushNotificationService(messaging: mockMessaging);

      final token = await service.fetchFcmToken();

      expect(token, isNull);
    });

    test('positive: onTokenRefresh updates fcmToken reactively', () async {
      final service = PushNotificationService(messaging: mockMessaging);
      await service.initialize();

      tokenRefreshController.add('new-refreshed-token-999');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(service.fcmToken.value, 'new-refreshed-token-999');
    });

    test('positive: background handler executes without throwing', () async {
      const message = RemoteMessage(
        messageId: 'msg-001',
        notification: RemoteNotification(
          title: 'Bonus Reward',
          body: 'You received 500 bonus points!',
        ),
      );

      expect(
        () => firebaseMessagingBackgroundHandler(message),
        returnsNormally,
      );
    });
  });
}
