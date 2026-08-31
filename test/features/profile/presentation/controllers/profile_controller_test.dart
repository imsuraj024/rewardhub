import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:rewardhub/features/profile/presentation/controllers/profile_controller.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockAuthController extends Mock implements AuthController {}

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

ProfileModel _profile({int points = 100}) =>
    ProfileModel(id: '1', name: 'Ada', mobile: '9876543210', points: points);

void main() {
  late AnalyticsHarness analytics;
  late MockAuthController auth;
  late MockGetProfileUseCase getProfile;

  setUp(() {
    analytics = AnalyticsHarness();
    installGetTestHarness();
    auth = MockAuthController();
    getProfile = MockGetProfileUseCase();
  });

  tearDown(resetGet);

  ProfileController build() =>
      ProfileController(
        authController: auth,
        getProfile: getProfile,
        analytics: analytics.analytics,
      );

  group('loadProfile', () {
    test('positive: fetches and exposes profile via success state', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => getProfile.call(any())).thenAnswer((_) async => _profile());
      final c = build();

      await c.loadProfile();

      expect(c.state, isA<ViewStateSuccess<ProfileModel>>());
      expect(c.profile, isNotNull);
      expect(c.profile!.points, 100);
      verify(() => getProfile.call('jwt')).called(1);
    });

    test('negative: null token does nothing, stays initial', () async {
      when(() => auth.token).thenReturn(null);
      final c = build();

      await c.loadProfile();

      expect(c.state, isA<ViewStateInitial<ProfileModel>>());
      expect(c.profile, isNull);
      verifyNever(() => getProfile.call(any()));
    });

    test('negative: thrown error surfaces as error state', () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => getProfile.call(any())).thenThrow(ApiException('boom'));
      final c = build();

      await c.loadProfile();

      expect(c.state, isA<ViewStateError<ProfileModel>>());
      expect(c.state.errorMessage, 'boom');
      expect(c.profile, isNull);
    });

    test('edge: error after a prior success keeps existing data on screen',
        () async {
      when(() => auth.token).thenReturn('jwt');
      when(() => getProfile.call(any())).thenAnswer((_) async => _profile());
      final c = build();
      await c.loadProfile();
      expect(c.state, isA<ViewStateSuccess<ProfileModel>>());

      when(() => getProfile.call(any())).thenThrow(ApiException('later fail'));
      await c.loadProfile();

      // Existing success is preserved rather than replaced with an error.
      expect(c.state, isA<ViewStateSuccess<ProfileModel>>());
      expect(c.profile, isNotNull);
    });

    test('edge: concurrent calls are coalesced (only one request)', () async {
      when(() => auth.token).thenReturn('jwt');
      final completer = Completer<ProfileModel>();
      when(() => getProfile.call(any())).thenAnswer((_) => completer.future);
      final c = build();

      final f1 = c.loadProfile();
      final f2 = c.loadProfile();
      expect(c.state, isA<ViewStateLoading<ProfileModel>>());

      completer.complete(_profile());
      await Future.wait([f1, f2]);

      verify(() => getProfile.call('jwt')).called(1);
    });

    test('positive: loading state shown when nothing is displayed yet',
        () async {
      when(() => auth.token).thenReturn('jwt');
      final completer = Completer<ProfileModel>();
      when(() => getProfile.call(any())).thenAnswer((_) => completer.future);
      final c = build();

      final future = c.loadProfile();
      expect(c.state, isA<ViewStateLoading<ProfileModel>>());

      completer.complete(_profile());
      await future;
    });
  });

  group('onInit', () {
    test('positive: loads when a session token already exists', () async {
      final tokenRx = Rxn<String>('jwt');
      when(() => auth.tokenListenable).thenReturn(tokenRx);
      when(() => auth.token).thenAnswer((_) => tokenRx.value);
      when(() => getProfile.call(any())).thenAnswer((_) async => _profile());
      final c = build();

      c.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(c.state, isA<ViewStateSuccess<ProfileModel>>());
    });

    test('edge: loads when token becomes available after init', () async {
      final tokenRx = Rxn<String>();
      when(() => auth.tokenListenable).thenReturn(tokenRx);
      when(() => auth.token).thenAnswer((_) => tokenRx.value);
      when(() => getProfile.call(any())).thenAnswer((_) async => _profile());
      final c = build();

      c.onInit();
      await Future<void>.delayed(Duration.zero);
      // No token yet -> nothing loaded.
      expect(c.state, isA<ViewStateInitial<ProfileModel>>());

      tokenRx.value = 'jwt';
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(c.state, isA<ViewStateSuccess<ProfileModel>>());
    });
  });
}
