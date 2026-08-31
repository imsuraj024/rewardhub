import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';

import '../../helpers/harness.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class FakeRemoteConfigSettings extends Fake implements RemoteConfigSettings {}

void main() {
  late MockFirebaseRemoteConfig mockRemoteConfig;
  late StreamController<RemoteConfigUpdate> updateController;

  setUpAll(() {
    registerFallbackValue(FakeRemoteConfigSettings());
  });

  setUp(() {
    installGetTestHarness();
    mockRemoteConfig = MockFirebaseRemoteConfig();
    updateController = StreamController<RemoteConfigUpdate>.broadcast();

    when(
      () => mockRemoteConfig.setConfigSettings(any()),
    ).thenAnswer((_) async {});
    when(() => mockRemoteConfig.setDefaults(any())).thenAnswer((_) async {});
    when(
      () => mockRemoteConfig.fetchAndActivate(),
    ).thenAnswer((_) async => true);
    when(
      () => mockRemoteConfig.onConfigUpdated,
    ).thenAnswer((_) => updateController.stream);
    when(() => mockRemoteConfig.activate()).thenAnswer((_) async => true);
  });

  tearDown(() async {
    await updateController.close();
    await resetGet();
  });

  RemoteConfigService createService() =>
      RemoteConfigService(remoteConfig: mockRemoteConfig);

  group('initialize', () {
    test(
      'positive: configures settings, defaults, and fetches values',
      () async {
        final service = createService();

        await service.initialize();

        verify(() => mockRemoteConfig.setConfigSettings(any())).called(1);
        verify(
          () => mockRemoteConfig.setDefaults(RemoteConfigDefaults.defaults),
        ).called(1);
        verify(() => mockRemoteConfig.fetchAndActivate()).called(1);
      },
    );

    test('negative: handles initialization errors gracefully', () async {
      when(
        () => mockRemoteConfig.setConfigSettings(any()),
      ).thenThrow(Exception('Config error'));
      final service = createService();

      await expectLater(service.initialize(), completes);
    });
  });

  group('fetchAndActivate', () {
    test('positive: returns true when activation succeeds', () async {
      final service = createService();

      final result = await service.fetchAndActivate();

      expect(result, isTrue);
      verify(() => mockRemoteConfig.fetchAndActivate()).called(1);
    });

    test('negative: returns false when activation throws', () async {
      when(
        () => mockRemoteConfig.fetchAndActivate(),
      ).thenThrow(Exception('Network error'));
      final service = createService();

      final result = await service.fetchAndActivate();

      expect(result, isFalse);
    });
  });

  group('typed getters & defaults', () {
    test('positive: getString returns config value when present', () {
      when(
        () => mockRemoteConfig.getString(RemoteConfigKeys.supportPhone),
      ).thenReturn('+91 99999 88888');
      final service = createService();

      expect(
        service.getString(RemoteConfigKeys.supportPhone),
        '+91 99999 88888',
      );
      expect(service.supportPhone, '+91 99999 88888');
    });

    test('edge: getString falls back to defaults when error occurs', () {
      when(
        () => mockRemoteConfig.getString(RemoteConfigKeys.supportPhone),
      ).thenThrow(Exception('read error'));
      final service = createService();

      expect(
        service.supportPhone,
        RemoteConfigDefaults.defaults[RemoteConfigKeys.supportPhone],
      );
    });

    test('positive: getBool returns config boolean value', () {
      when(
        () => mockRemoteConfig.getBool(RemoteConfigKeys.maintenanceMode),
      ).thenReturn(true);
      final service = createService();

      expect(service.getBool(RemoteConfigKeys.maintenanceMode), isTrue);
      expect(service.isMaintenanceMode, isTrue);
    });

    test('positive: getInt returns integer value', () {
      when(() => mockRemoteConfig.getInt('test_count')).thenReturn(100);
      final service = createService();

      expect(service.getInt('test_count'), 100);
    });

    test('positive: getDouble returns double value', () {
      when(() => mockRemoteConfig.getDouble('tax_rate')).thenReturn(0.18);
      final service = createService();

      expect(service.getDouble('tax_rate'), 0.18);
    });

    test('positive: typed convenience getters return expected default types', () {
      when(() => mockRemoteConfig.getString(any())).thenThrow(Exception());
      when(() => mockRemoteConfig.getBool(any())).thenThrow(Exception());
      when(() => mockRemoteConfig.getInt(any())).thenThrow(Exception());
      when(() => mockRemoteConfig.getDouble(any())).thenThrow(Exception());

      final service = createService();

      expect(service.isMaintenanceMode, isFalse);
      expect(
        service.maintenanceMessage,
        'RewardHub is undergoing scheduled maintenance. Please check back shortly.',
      );
      expect(service.supportPhone, '+91 98765 43210');
      expect(service.supportEmail, 'support@kitoxhardware.com');
      expect(service.latestVersion, '');
      expect(
        service.catalogueUrl,
        'https://raw.githubusercontent.com/mozilla/pdf.js/master/web/compressed.tracemonkey-pldi-09.pdf',
      );
    });

    test(
      'positive: latestVersion, catalogueUrl and releaseNotes reflect remote values',
      () {
        when(
          () => mockRemoteConfig.getString(RemoteConfigKeys.latestVersion),
        ).thenReturn('1.0.0');
        when(
          () => mockRemoteConfig.getString(RemoteConfigKeys.catalogueUrl),
        ).thenReturn('https://example.com/custom_catalogue.pdf');
        when(
          () => mockRemoteConfig.getString(RemoteConfigKeys.releaseNotes),
        ).thenReturn('• New features\n• Bug fixes');

        final service = createService();

        expect(service.latestVersion, '1.0.0');
        expect(
          service.catalogueUrl,
          'https://example.com/custom_catalogue.pdf',
        );
        expect(service.releaseNotes, '• New features\n• Bug fixes');
      },
    );

    test('positive: releaseNotes returns null when empty or string "null"', () {
      when(
        () => mockRemoteConfig.getString(RemoteConfigKeys.releaseNotes),
      ).thenReturn('');
      final service = createService();
      expect(service.releaseNotes, isNull);

      when(
        () => mockRemoteConfig.getString(RemoteConfigKeys.releaseNotes),
      ).thenReturn('null');
      expect(service.releaseNotes, isNull);
    });

    test(
      'positive: promotionalBanners parses list or single object and filters inactive',
      () {
        when(
          () => mockRemoteConfig.getString(RemoteConfigKeys.promotionalBanner),
        ).thenReturn('''[
            {"id": "b1", "title": "Double Points", "subtitle": "Scan QR", "order": 2, "isActive": true},
            {"id": "b2", "title": "Expired Promo", "subtitle": "Ended", "order": 1, "isActive": false},
            {"id": "b3", "title": "Catalogue", "subtitle": "Browse 2026", "order": 1, "isActive": true}
          ]''');
        final service = createService();
        final banners = service.promotionalBanners;
        expect(banners.length, 2);
        expect(banners[0].id, 'b3');
        expect(banners[1].id, 'b1');

        // Test single object format
        when(
          () => mockRemoteConfig.getString(RemoteConfigKeys.promotionalBanner),
        ).thenReturn(
          '{"id": "single", "title": "Flash Sale", "subtitle": "Today only", "isActive": true}',
        );
        final singleBanners = service.promotionalBanners;
        expect(singleBanners.length, 1);
        expect(singleBanners[0].title, 'Flash Sale');

        // Test invalid or null
        when(
          () => mockRemoteConfig.getString(RemoteConfigKeys.promotionalBanner),
        ).thenReturn('');
        expect(service.promotionalBanners, isEmpty);
      },
    );
  });

  group('realtime updates & onClose', () {
    test('positive: activates updated keys on realtime update event', () async {
      final service = createService();
      await service.initialize();

      updateController.add(
        RemoteConfigUpdate({RemoteConfigKeys.maintenanceMode}),
      );
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRemoteConfig.activate()).called(1);
    });

    test(
      'positive: onClose cleans up stream subscription without throwing',
      () {
        final service = createService();
        service.onClose();
      },
    );
  });
}
