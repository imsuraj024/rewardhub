import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/domain/usecases/get_recent_activities_usecase.dart';
import 'package:rewardhub/features/home/presentation/controllers/home_controller.dart';

import '../../../../helpers/harness.dart';

class MockAuthController extends Mock implements AuthController {}

class MockGetRecentActivitiesUseCase extends Mock
    implements GetRecentActivitiesUseCase {}

List<RecentActivityModel> _activities() => [
      RecentActivityModel(
        id: '1',
        type: 'credit',
        points: 50,
        date: DateTime(2024, 1, 1),
      ),
    ];

void main() {
  late MockAuthController auth;
  late MockGetRecentActivitiesUseCase getActivities;

  setUp(() {
    installGetTestHarness();
    auth = MockAuthController();
    getActivities = MockGetRecentActivitiesUseCase();
  });

  tearDown(resetGet);

  HomeController build() => HomeController(
        authController: auth,
        getRecentActivities: getActivities,
      );

  group('loadActivities', () {
    test('positive: fetches and exposes activities via success state',
        () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => getActivities.call(any()))
          .thenAnswer((_) async => _activities());
      final c = build();

      await c.loadActivities();

      expect(c.state, isA<ViewStateSuccess<List<RecentActivityModel>>>());
      final data =
          (c.state as ViewStateSuccess<List<RecentActivityModel>>).data;
      expect(data, hasLength(1));
      verify(() => getActivities.call('jwt')).called(1);
    });

    test('positive: empty list is still a success state', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => getActivities.call(any())).thenAnswer((_) async => []);
      final c = build();

      await c.loadActivities();

      expect(c.state, isA<ViewStateSuccess<List<RecentActivityModel>>>());
    });

    test('negative: null token does nothing, stays initial', () async {
      when(() => auth.token).thenReturn(null);
      final c = build();

      await c.loadActivities();

      expect(c.state, isA<ViewStateInitial<List<RecentActivityModel>>>());
      verifyNever(() => getActivities.call(any()));
    });

    test('negative: thrown error surfaces as error state', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => getActivities.call(any())).thenThrow(ApiException('boom'));
      final c = build();

      await c.loadActivities();

      expect(c.state, isA<ViewStateError<List<RecentActivityModel>>>());
      expect(c.state.errorMessage, 'boom');
    });

    test('edge: error after prior success keeps existing data', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => getActivities.call(any()))
          .thenAnswer((_) async => _activities());
      final c = build();
      await c.loadActivities();
      expect(c.state, isA<ViewStateSuccess<List<RecentActivityModel>>>());

      when(() => getActivities.call(any())).thenThrow(ApiException('later'));
      await c.loadActivities();

      expect(c.state, isA<ViewStateSuccess<List<RecentActivityModel>>>());
    });

    test('edge: concurrent calls are coalesced (only one request)', () async {
      when(() => auth.token).thenReturn('jwt');
      final completer = Completer<List<RecentActivityModel>>();
      when(() => getActivities.call(any())).thenAnswer((_) => completer.future);
      final c = build();

      final f1 = c.loadActivities();
      final f2 = c.loadActivities();
      expect(c.state, isA<ViewStateLoading<List<RecentActivityModel>>>());

      completer.complete(_activities());
      await Future.wait([f1, f2]);

      verify(() => getActivities.call('jwt')).called(1);
    });
  });

  group('onInit', () {
    test('positive: loads when session token already exists', () async {
      final tokenRx = Rxn<String>('jwt');
      when(() => auth.tokenListenable).thenReturn(tokenRx);
      when(() => auth.token).thenAnswer((_) => tokenRx.value);
      when(() => getActivities.call(any()))
          .thenAnswer((_) async => _activities());
      final c = build();

      c.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(c.state, isA<ViewStateSuccess<List<RecentActivityModel>>>());
    });

    test('edge: loads when token becomes available after init', () async {
      final tokenRx = Rxn<String>();
      when(() => auth.tokenListenable).thenReturn(tokenRx);
      when(() => auth.token).thenAnswer((_) => tokenRx.value);
      when(() => getActivities.call(any()))
          .thenAnswer((_) async => _activities());
      final c = build();

      c.onInit();
      await Future<void>.delayed(Duration.zero);
      expect(c.state, isA<ViewStateInitial<List<RecentActivityModel>>>());

      tokenRx.value = 'jwt';
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(c.state, isA<ViewStateSuccess<List<RecentActivityModel>>>());
    });
  });
}
