import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/analytics/firebase_analytics_service.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late MockFirebaseAnalytics mockAnalytics;
  late FirebaseAnalyticsService service;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    service = FirebaseAnalyticsService(analytics: mockAnalytics);

    when(() => mockAnalytics.setAnalyticsCollectionEnabled(any()))
        .thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        )).thenAnswer((_) async {});
    when(() => mockAnalytics.logScreenView(
          screenName: any(named: 'screenName'),
        )).thenAnswer((_) async {});
    when(() => mockAnalytics.logLogin(
          loginMethod: any(named: 'loginMethod'),
        )).thenAnswer((_) async {});
    when(() => mockAnalytics.logSignUp(
          signUpMethod: any(named: 'signUpMethod'),
        )).thenAnswer((_) async {});
    when(() => mockAnalytics.logSelectContent(
          contentType: any(named: 'contentType'),
          itemId: any(named: 'itemId'),
        )).thenAnswer((_) async {});
    when(() => mockAnalytics.setUserId(id: any(named: 'id')))
        .thenAnswer((_) async {});
    when(() => mockAnalytics.setUserProperty(
          name: any(named: 'name'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    when(() => mockAnalytics.resetAnalyticsData()).thenAnswer((_) async {});
  });

  group('FirebaseAnalyticsService', () {
    test('positive: setCollectionEnabled delegates to FirebaseAnalytics', () async {
      await service.setCollectionEnabled(true);
      verify(() => mockAnalytics.setAnalyticsCollectionEnabled(true)).called(1);

      await service.setCollectionEnabled(false);
      verify(() => mockAnalytics.setAnalyticsCollectionEnabled(false)).called(1);
    });

    test('positive: logEvent logs with parameters or null when empty', () async {
      await service.logEvent('button_tap', {'id': 'scan_cta'});
      verify(() => mockAnalytics.logEvent(
            name: 'button_tap',
            parameters: {'id': 'scan_cta'},
          )).called(1);

      await service.logEvent('app_opened');
      verify(() => mockAnalytics.logEvent(
            name: 'app_opened',
            parameters: null,
          )).called(1);
    });

    test('positive: logScreenView delegates screenName', () async {
      await service.logScreenView(screenName: 'home');
      verify(() => mockAnalytics.logScreenView(screenName: 'home')).called(1);
    });

    test('positive: logLogin delegates method', () async {
      await service.logLogin(method: 'phone_otp');
      verify(() => mockAnalytics.logLogin(loginMethod: 'phone_otp')).called(1);
    });

    test('positive: logSignUp delegates method', () async {
      await service.logSignUp(method: 'phone_otp');
      verify(() => mockAnalytics.logSignUp(signUpMethod: 'phone_otp')).called(1);
    });

    test('positive: logSelectContent delegates contentType and itemId', () async {
      await service.logSelectContent(contentType: 'reward', itemId: 'r_101');
      verify(() => mockAnalytics.logSelectContent(
            contentType: 'reward',
            itemId: 'r_101',
          )).called(1);
    });

    test('positive: setUserId delegates id', () async {
      await service.setUserId('usr_123');
      verify(() => mockAnalytics.setUserId(id: 'usr_123')).called(1);

      await service.setUserId(null);
      verify(() => mockAnalytics.setUserId(id: null)).called(1);
    });

    test('positive: setUserProperty delegates name and value', () async {
      await service.setUserProperty(name: 'role', value: 'mechanic');
      verify(() => mockAnalytics.setUserProperty(name: 'role', value: 'mechanic'))
          .called(1);
    });

    test('positive: reset delegates to resetAnalyticsData', () async {
      await service.reset();
      verify(() => mockAnalytics.resetAnalyticsData()).called(1);
    });

    test('negative: swallows errors gracefully without throwing', () async {
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenThrow(Exception('Analytics unavailable'));

      await expectLater(service.logEvent('error_trigger'), completes);
    });

    test('positive: navigatorObserver returns valid instance', () {
      final observer = service.navigatorObserver;
      expect(observer, isA<NavigatorObserver>());
    });
  });
}
