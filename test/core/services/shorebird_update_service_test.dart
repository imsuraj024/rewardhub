import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'package:rewardhub/core/services/shorebird_update_service.dart';
import 'package:rewardhub/core/utils/app_toast.dart';

import '../../helpers/harness.dart';

class MockShorebirdUpdater extends Mock implements ShorebirdUpdater {}

void main() {
  late MockShorebirdUpdater mockUpdater;
  late List<RecordedToast> toasts;
  int restartCalls = 0;

  setUp(() {
    toasts = installGetTestHarness();
    mockUpdater = MockShorebirdUpdater();
    restartCalls = 0;
  });

  tearDown(resetGet);

  ShorebirdUpdateService createService({bool isAvailable = true}) {
    when(() => mockUpdater.isAvailable).thenReturn(isAvailable);
    when(() => mockUpdater.readCurrentPatch()).thenAnswer((_) async => null);
    return ShorebirdUpdateService(
      updater: mockUpdater,
      restartHandler: () async {
        restartCalls++;
      },
    );
  }

  group('initialization', () {
    test('positive: loads current patch on init when available', () async {
      when(() => mockUpdater.isAvailable).thenReturn(true);
      when(() => mockUpdater.readCurrentPatch()).thenAnswer(
        (_) async => const Patch(number: 3),
      );

      final service = ShorebirdUpdateService(
        updater: mockUpdater,
        restartHandler: () async {},
      );
      service.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(service.isAvailable, isTrue);
      expect(service.currentPatchNumber, 3);
    });

    test('positive: isAvailable reflects updater property', () {
      final service = createService(isAvailable: false);
      expect(service.isAvailable, isFalse);
    });
  });

  group('checkForUpdates', () {
    test('positive: when unavailable and manual, raises info toast', () async {
      final service = createService(isAvailable: false);

      await service.checkForUpdates(isManual: true);

      expect(service.isChecking, isFalse);
      expect(toasts.length, 1);
      expect(toasts.first.type, ToastType.info);
      expect(
        toasts.first.message,
        'Shorebird code push is not active in this build.',
      );
      verifyNever(() => mockUpdater.checkForUpdate());
    });

    test('positive: when unavailable and auto, silent no-op', () async {
      final service = createService(isAvailable: false);

      await service.checkForUpdates(isManual: false);

      expect(service.isChecking, isFalse);
      expect(toasts, isEmpty);
      verifyNever(() => mockUpdater.checkForUpdate());
    });

    test('positive: outdated status sets hasUpdateAvailable and shows dialog',
        () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.checkForUpdate()).thenAnswer(
        (_) async => UpdateStatus.outdated,
      );

      await service.checkForUpdates(isManual: false);

      expect(service.hasUpdateAvailable, isTrue);
      expect(service.isRestartRequired, isFalse);
      expect(service.isChecking, isFalse);
    });

    test(
        'positive: restartRequired status sets isRestartRequired and resets hasUpdateAvailable',
        () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.checkForUpdate()).thenAnswer(
        (_) async => UpdateStatus.restartRequired,
      );

      await service.checkForUpdates(isManual: false);

      expect(service.isRestartRequired, isTrue);
      expect(service.hasUpdateAvailable, isFalse);
    });

    test('positive: upToDate status with isManual shows success info toast',
        () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.checkForUpdate()).thenAnswer(
        (_) async => UpdateStatus.upToDate,
      );

      await service.checkForUpdates(isManual: true);

      expect(service.hasUpdateAvailable, isFalse);
      expect(toasts.length, 1);
      expect(toasts.first.type, ToastType.info);
      expect(toasts.first.message, 'You are on the latest version.');
    });

    test('positive: unavailable status with isManual shows info toast',
        () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.checkForUpdate()).thenAnswer(
        (_) async => UpdateStatus.unavailable,
      );

      await service.checkForUpdates(isManual: true);

      expect(service.hasUpdateAvailable, isFalse);
      expect(toasts.length, 1);
      expect(toasts.first.type, ToastType.info);
      expect(toasts.first.message, 'No updates are available right now.');
    });

    test('negative: updater exception in manual check shows error toast',
        () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.checkForUpdate()).thenThrow(Exception('Network error'));

      await service.checkForUpdates(isManual: true);

      expect(service.isChecking, isFalse);
      expect(toasts.length, 1);
      expect(toasts.first.type, ToastType.error);
      expect(
        toasts.first.message,
        'Could not check for updates. Please try again later.',
      );
    });
  });

  group('checkUpdateOnLaunch', () {
    test('positive: when unavailable, returns false immediately', () async {
      final service = createService(isAvailable: false);

      final result = await service.checkUpdateOnLaunch();

      expect(result, isFalse);
      verifyNever(() => mockUpdater.checkForUpdate());
    });

    test('positive: returns true and marks update available when outdated',
        () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.checkForUpdate()).thenAnswer(
        (_) async => UpdateStatus.outdated,
      );

      final result = await service.checkUpdateOnLaunch();

      expect(result, isTrue);
      expect(service.hasUpdateAvailable, isTrue);
    });

    test('positive: returns true and marks restart required when restartRequired',
        () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.checkForUpdate()).thenAnswer(
        (_) async => UpdateStatus.restartRequired,
      );

      final result = await service.checkUpdateOnLaunch();

      expect(result, isTrue);
      expect(service.isRestartRequired, isTrue);
    });

    test('positive: returns false and continues silently when up to date',
        () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.checkForUpdate()).thenAnswer(
        (_) async => UpdateStatus.upToDate,
      );

      final result = await service.checkUpdateOnLaunch();

      expect(result, isFalse);
      expect(service.hasUpdateAvailable, isFalse);
      expect(toasts, isEmpty);
    });

    test('negative: returns false when update check throws an exception',
        () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.checkForUpdate()).thenThrow(Exception('Network timeout'));

      final result = await service.checkUpdateOnLaunch();

      expect(result, isFalse);
    });
  });

  group('downloadAndApplyUpdate', () {
    test('positive: downloads patch and marks restartRequired', () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.update()).thenAnswer((_) async {});

      final result = await service.downloadAndApplyUpdate();

      expect(result, isTrue);
      expect(service.isDownloading, isFalse);
      expect(service.isRestartRequired, isTrue);
      expect(service.hasUpdateAvailable, isFalse);
      verify(() => mockUpdater.update()).called(1);
    });

    test('negative: update failure shows toast and returns false', () async {
      final service = createService(isAvailable: true);
      when(() => mockUpdater.update()).thenThrow(Exception('Download failed'));

      final result = await service.downloadAndApplyUpdate();

      expect(result, isFalse);
      expect(service.isDownloading, isFalse);
      expect(service.isRestartRequired, isFalse);
      expect(toasts.length, 1);
      expect(toasts.first.type, ToastType.error);
      expect(
        toasts.first.message,
        'Failed to download the update. Please check your connection and try again.',
      );
    });
  });

  group('restartApp', () {
    test('positive: invokes restartHandler callback', () async {
      final service = createService(isAvailable: true);

      await service.restartApp();

      expect(restartCalls, 1);
    });
  });
}
