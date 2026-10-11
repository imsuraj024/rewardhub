import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/kyc_controller.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockAuthController extends Mock implements AuthController {}

class MockRegistrationDraftStore extends Mock
    implements RegistrationDraftStore {}

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late AnalyticsHarness analytics;
  late MockAuthController auth;
  late MockRegistrationDraftStore store;
  late List<RecordedToast> toasts;
  late Directory tempDir;
  late String keptDir;

  setUpAll(() {
    registerFallbackValue(const RegistrationDraft());
    registerFallbackValue(ImageSource.camera);
    registerFallbackValue(CameraDevice.rear);
  });

  setUp(() {
    analytics = AnalyticsHarness();
    toasts = installGetTestHarness();
    auth = MockAuthController();
    store = MockRegistrationDraftStore();
    tempDir = Directory.systemTemp.createTempSync('kyc_test_');
    keptDir = '${tempDir.path}/kyc_draft';
    when(() => store.read()).thenAnswer((_) async => const RegistrationDraft());
    when(() => store.save(any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await resetGet();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  void stubRegister() {
    when(
      () => auth.register(
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        referralCode: any(named: 'referralCode'),
        accountNumber: any(named: 'accountNumber'),
        ifscCode: any(named: 'ifscCode'),
        upiId: any(named: 'upiId'),
        selfiePhotoPath: any(named: 'selfiePhotoPath'),
        aadharPhotoPath: any(named: 'aadharPhotoPath'),
      ),
    ).thenAnswer((_) async {});
  }

  void verifyNoRegister() {
    verifyNever(
      () => auth.register(
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        referralCode: any(named: 'referralCode'),
        accountNumber: any(named: 'accountNumber'),
        ifscCode: any(named: 'ifscCode'),
        upiId: any(named: 'upiId'),
        selfiePhotoPath: any(named: 'selfiePhotoPath'),
        aadharPhotoPath: any(named: 'aadharPhotoPath'),
      ),
    );
  }

  /// Every test stores photos under its own temp directory and never reads
  /// the real camera permission or opens the real settings.
  KycController build({
    ImagePicker? picker,
    Future<Directory> Function()? photoDirectory,
    Future<PermissionStatus> Function()? readCameraStatus,
    Future<bool> Function()? launchSettings,
  }) =>
      KycController(
        store,
        auth,
        analytics.analytics,
        picker: picker,
        photoDirectory: photoDirectory ?? () async => tempDir,
        readCameraStatus:
            readCameraStatus ?? () async => PermissionStatus.denied,
        launchSettings: launchSettings ?? () async => true,
      );

  /// Writes a real file under the temp directory and returns its path.
  String photo(String relativePath, [List<int> bytes = const [1, 2, 3]]) {
    final file = File('${tempDir.path}/$relativePath')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    return file.path;
  }

  /// Stubs every named argument `_capture` passes, so the stub matches the
  /// real call.
  When<Future<XFile?>> whenPick(MockImagePicker picker) => when(
        () => picker.pickImage(
          source: any(named: 'source'),
          imageQuality: any(named: 'imageQuality'),
          maxWidth: any(named: 'maxWidth'),
          preferredCameraDevice: any(named: 'preferredCameraDevice'),
          requestFullMetadata: any(named: 'requestFullMetadata'),
        ),
      );

  void verifyPicks(MockImagePicker picker, int times) => verify(
        () => picker.pickImage(
          source: any(named: 'source'),
          imageQuality: any(named: 'imageQuality'),
          maxWidth: any(named: 'maxWidth'),
          preferredCameraDevice: any(named: 'preferredCameraDevice'),
          requestFullMetadata: any(named: 'requestFullMetadata'),
        ),
      ).called(times);

  /// A picker that hands back a real picked file.
  MockImagePicker pickerReturning(String path) {
    final picker = MockImagePicker();
    whenPick(picker).thenAnswer((_) async => XFile(path));
    return picker;
  }

  /// A picker that fails with [error].
  MockImagePicker pickerThrowing(Object error) {
    final picker = MockImagePicker();
    whenPick(picker).thenThrow(error);
    return picker;
  }

  RegistrationDraft lastSaved() =>
      verify(() => store.save(captureAny())).captured.last as RegistrationDraft;

  group('getters', () {
    test('positive: isLoading and errorMessage delegate to auth', () {
      when(() => auth.isLoading).thenReturn(true);
      when(() => auth.errorMessage).thenReturn('oops');
      final c = build();

      expect(c.isLoading, isTrue);
      expect(c.errorMessage, 'oops');
    });
  });

  group('onReady', () {
    test('positive: clears any stale auth error', () {
      when(() => auth.clearError()).thenReturn(null);
      final c = build();

      c.onReady();

      verify(() => auth.clearError()).called(1);
    });
  });

  group('onInit / prefill', () {
    test('positive: prefills the image paths from the draft', () async {
      final aadhaar = photo('kyc_draft/aadhaar_1.jpg');
      final selfie = photo('kyc_draft/selfie_2.jpg');
      when(() => store.read()).thenAnswer(
        (_) async => RegistrationDraft(
          aadhaarPath: aadhaar,
          selfiePath: selfie,
        ),
      );
      final c = build();

      c.onInit();
      await c.prefilled;

      expect(c.aadhaarPath.value, aadhaar);
      expect(c.selfiePath.value, selfie);
    });

    test('positive: onInit keeps existing photos without saving', () async {
      final aadhaar = photo('kyc_draft/aadhaar_1.jpg');
      final selfie = photo('kyc_draft/selfie_2.jpg');
      when(() => store.read()).thenAnswer(
        (_) async => RegistrationDraft(
          aadhaarPath: aadhaar,
          selfiePath: selfie,
        ),
      );
      final c = build();

      c.onInit();
      await c.prefilled;

      expect(c.aadhaarPath.value, aadhaar);
      expect(c.selfiePath.value, selfie);
      verifyNever(() => store.save(any()));
    });

    test(
        'negative: onInit drops a draft photo whose file is gone and keeps '
        'the other fields', () async {
      final aadhaar = photo('kyc_draft/aadhaar_1.jpg');
      when(() => store.read()).thenAnswer(
        (_) async => RegistrationDraft(
          name: 'Ramesh Kumar',
          phone: '9876543210',
          referral: 'KITOX1',
          upi: 'ramesh@okaxis',
          accountNumber: '123456789012',
          ifsc: 'HDFC0001234',
          aadhaarPath: aadhaar,
          selfiePath: '$keptDir/selfie_2.jpg',
        ),
      );
      final c = build();

      c.onInit();
      await c.prefilled;

      expect(c.aadhaarPath.value, aadhaar);
      expect(c.selfiePath.value, '');
      final saved = verify(() => store.save(captureAny())).captured.single
          as RegistrationDraft;
      expect(saved.name, 'Ramesh Kumar');
      expect(saved.phone, '9876543210');
      expect(saved.referral, 'KITOX1');
      expect(saved.upi, 'ramesh@okaxis');
      expect(saved.accountNumber, '123456789012');
      expect(saved.ifsc, 'HDFC0001234');
      expect(saved.aadhaarPath, aadhaar);
      expect(saved.selfiePath, '');
    });

    test('edge: an empty file counts as missing', () async {
      final aadhaar = photo('kyc_draft/aadhaar_1.jpg', const []);
      final selfie = photo('kyc_draft/selfie_2.jpg');
      when(() => store.read()).thenAnswer(
        (_) async => RegistrationDraft(
          aadhaarPath: aadhaar,
          selfiePath: selfie,
        ),
      );
      final c = build();

      c.onInit();
      await c.prefilled;

      expect(c.aadhaarPath.value, '');
      expect(c.selfiePath.value, selfie);
      verify(() => store.save(any())).called(1);
    });

    test('edge: a kept photo whose app folder moved is found by name',
        () async {
      final moved = photo('kyc_draft/aadhaar_1.jpg');
      final selfie = photo('kyc_draft/selfie_2.jpg');
      when(() => store.read()).thenAnswer(
        (_) async => RegistrationDraft(
          aadhaarPath: '/old/container/kyc_draft/aadhaar_1.jpg',
          selfiePath: selfie,
        ),
      );
      final c = build();

      c.onInit();
      await c.prefilled;

      expect(c.aadhaarPath.value, moved);
      final saved = verify(() => store.save(captureAny())).captured.single
          as RegistrationDraft;
      expect(saved.aadhaarPath, moved);
      expect(saved.selfiePath, selfie);
    });

    test('edge: a pick made while the draft loads keeps the new photo',
        () async {
      final read = Completer<RegistrationDraft>();
      when(() => store.read()).thenAnswer((_) => read.future);
      final c = build(picker: pickerReturning(photo('cache/picked.jpg')));

      c.onInit();
      final pick = c.pickAadhaar(ImageSource.gallery);
      // Real time: long enough for an unguarded pick to copy and save before
      // the draft read finishes, which would then blank the new photo.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      read.complete(
        const RegistrationDraft(name: 'Ramesh Kumar', phone: '9876543210'),
      );

      expect(await pick, KycPickResult.added);
      expect(c.aadhaarPath.value, startsWith('$keptDir/aadhaar_'));
      final saved = lastSaved();
      expect(saved.aadhaarPath, c.aadhaarPath.value);
      expect(saved.name, 'Ramesh Kumar');
      expect(saved.phone, '9876543210');
    });
  });

  group('onSubmit', () {
    test('negative: missing aadhaar warns and does not register', () async {
      stubRegister();
      final c = build();
      c.selfiePath.value = '/s.png';
      // aadhaar empty.

      await c.onSubmit();

      verifyNever(
        () => auth.register(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          referralCode: any(named: 'referralCode'),
        ),
      );
    });

    test('negative: missing selfie warns and does not register', () async {
      stubRegister();
      final c = build();
      c.aadhaarPath.value = '/a.png';
      // selfie empty.

      await c.onSubmit();

      verifyNever(
        () => auth.register(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          referralCode: any(named: 'referralCode'),
        ),
      );
    });

    test('positive: both present -> persists, registers, clears draft',
        () async {
      stubRegister();
      when(() => auth.errorMessage).thenReturn(null);
      final c = build();
      c.aadhaarPath.value = photo('a.png');
      c.selfiePath.value = photo('s.png');

      await c.onSubmit();

      verify(() => store.save(any())).called(1);
      verify(
        () => auth.register(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          referralCode: any(named: 'referralCode'),
          accountNumber: any(named: 'accountNumber'),
          ifscCode: any(named: 'ifscCode'),
          upiId: any(named: 'upiId'),
          selfiePhotoPath: any(named: 'selfiePhotoPath'),
          aadharPhotoPath: any(named: 'aadharPhotoPath'),
        ),
      ).called(1);
      verify(() => store.clear()).called(1);
    });

    test('negative: register error keeps draft (no clear)', () async {
      stubRegister();
      when(() => auth.errorMessage).thenReturn('server rejected');
      final c = build();
      c.aadhaarPath.value = photo('a.png');
      c.selfiePath.value = photo('s.png');

      await c.onSubmit();

      verify(() => store.save(any())).called(1);
      verifyNever(() => store.clear());
    });

    test('negative: submit drops a photo deleted after it was added', () async {
      stubRegister();
      final aadhaar = photo('kyc_draft/aadhaar_1.jpg');
      final selfie = photo('kyc_draft/selfie_2.jpg');
      final c = build();
      c.aadhaarPath.value = aadhaar;
      c.selfiePath.value = selfie;
      File(aadhaar).deleteSync();

      await c.onSubmit();

      expect(c.aadhaarPath.value, '');
      expect(c.selfiePath.value, selfie);
      expect(lastSaved().aadhaarPath, '');
      final incomplete = analytics.call('kyc_incomplete');
      expect(incomplete?.parameters, {
        'has_aadhaar': false,
        'has_selfie': true,
      });
      expect(toasts.single.type, ToastType.warning);
      expect(
        toasts.single.message,
        'Add your Aadhaar photo and a selfie to continue.',
      );
      verifyNoRegister();
    });

    test('positive: a successful submit deletes the kept photos', () async {
      stubRegister();
      when(() => auth.errorMessage).thenReturn(null);
      final c = build();
      c.aadhaarPath.value = photo('kyc_draft/aadhaar_1.jpg');
      c.selfiePath.value = photo('kyc_draft/selfie_2.jpg');

      await c.onSubmit();

      verify(() => store.clear()).called(1);
      expect(Directory(keptDir).existsSync(), isFalse);
    });

    test('negative: a failed submit keeps the photos', () async {
      stubRegister();
      when(() => auth.errorMessage).thenReturn('server rejected');
      final aadhaar = photo('kyc_draft/aadhaar_1.jpg');
      final selfie = photo('kyc_draft/selfie_2.jpg');
      final c = build();
      c.aadhaarPath.value = aadhaar;
      c.selfiePath.value = selfie;

      await c.onSubmit();

      expect(File(aadhaar).existsSync(), isTrue);
      expect(File(selfie).existsSync(), isTrue);
      expect(c.aadhaarPath.value, aadhaar);
      expect(c.selfiePath.value, selfie);
      verifyNever(() => store.clear());
    });
  });

  group('pickAadhaar / pickSelfie (no platform available)', () {
    test('edge: pickAadhaar handles missing plugin gracefully', () async {
      final c = build();

      // ImagePicker hits a MethodChannel that has no test handler; the
      // controller catches the failure, shows a toast and leaves state clean.
      await c.pickAadhaar(ImageSource.gallery);

      expect(c.aadhaarPath.value, '');
      verifyNever(() => store.save(any()));
    });

    test('edge: pickSelfie handles missing plugin gracefully', () async {
      final c = build();

      await c.pickSelfie();

      expect(c.selfiePath.value, '');
      verifyNever(() => store.save(any()));
    });
  });

  group('cameraAccess (DS-26)', () {
    final expected = {
      PermissionStatus.granted: KycCameraAccess.ready,
      PermissionStatus.limited: KycCameraAccess.ready,
      PermissionStatus.permanentlyDenied: KycCameraAccess.blocked,
      PermissionStatus.restricted: KycCameraAccess.blocked,
      PermissionStatus.denied: KycCameraAccess.explain,
      PermissionStatus.provisional: KycCameraAccess.explain,
    };
    for (final entry in expected.entries) {
      test('edge: ${entry.key.name} -> ${entry.value.name}', () async {
        final c = build(readCameraStatus: () async => entry.key);

        expect(await c.cameraAccess(), entry.value);
      });
    }

    test('positive: denied after cameraExplained is ready', () async {
      final c = build(readCameraStatus: () async => PermissionStatus.denied);

      expect(await c.cameraAccess(), KycCameraAccess.explain);
      c.cameraExplained();

      expect(await c.cameraAccess(), KycCameraAccess.ready);
    });

    test('edge: a blocked camera stays blocked after cameraExplained',
        () async {
      final c = build(
        readCameraStatus: () async => PermissionStatus.permanentlyDenied,
      );
      c.cameraExplained();

      expect(await c.cameraAccess(), KycCameraAccess.blocked);
    });

    test('negative: a status read that throws asks for the rationale',
        () async {
      final c = build(
        readCameraStatus: () async => throw MissingPluginException(),
      );

      expect(await c.cameraAccess(), KycCameraAccess.explain);
    });

    test('positive: openSettings calls the launcher once', () async {
      var launches = 0;
      final c = build(launchSettings: () async {
        launches++;
        return true;
      });

      await c.openSettings();

      expect(launches, 1);
    });

    test('negative: a launcher that throws does not escape', () async {
      final c = build(
        launchSettings: () async => throw MissingPluginException(),
      );

      await expectLater(c.openSettings(), completes);
      expect(toasts, isEmpty);
    });
  });

  group('pick outcomes (DS-27)', () {
    for (final code in ['camera_access_denied', 'camera_access_restricted']) {
      test(
          'negative: a camera denial returns cameraBlocked without a toast '
          '($code)', () async {
        final picker = pickerThrowing(PlatformException(code: code));
        final c = build(picker: picker);
        c.selfiePath.value = '/kept/selfie.jpg';

        expect(await c.pickSelfie(), KycPickResult.cameraBlocked);

        expect(toasts, isEmpty);
        expect(analytics.calls, hasLength(1));
        expect(analytics.calls.single.name, 'kyc_capture_failed');
        expect(analytics.calls.single.parameters, {'source': 'camera'});
        expect(c.selfiePath.value, '/kept/selfie.jpg');
        verifyNever(() => store.save(any()));
      });
    }

    test('negative: another camera error is an ordinary failure', () async {
      final c = build(
        picker: pickerThrowing(PlatformException(code: 'no_available_camera')),
      );

      expect(
        await c.pickAadhaar(ImageSource.camera),
        KycPickResult.failed,
      );

      expect(toasts.single.type, ToastType.error);
      expect(toasts.single.title, "Couldn't open camera");
      expect(toasts.single.message, 'Please try again.');
      expect(analytics.calls.single.name, 'kyc_capture_failed');
      expect(analytics.calls.single.parameters, {'source': 'camera'});
    });

    test('edge: a gallery photo_access_denied is an ordinary failure',
        () async {
      final c = build(
        picker: pickerThrowing(PlatformException(code: 'photo_access_denied')),
      );

      expect(
        await c.pickAadhaar(ImageSource.gallery),
        KycPickResult.failed,
      );

      expect(toasts.single.type, ToastType.error);
      expect(toasts.single.title, "Couldn't open gallery");
      expect(toasts.single.message, 'Please try again.');
      expect(analytics.calls.single.name, 'kyc_capture_failed');
      expect(analytics.calls.single.parameters, {'source': 'gallery'});
      verifyNever(() => store.save(any()));
    });

    test('edge: cancelling the picker changes nothing', () async {
      final picker = MockImagePicker();
      whenPick(picker).thenAnswer((_) async => null);
      final c = build(picker: picker);
      c.aadhaarPath.value = '/kept/aadhaar.jpg';

      expect(await c.pickAadhaar(ImageSource.gallery), KycPickResult.cancelled);

      expect(c.aadhaarPath.value, '/kept/aadhaar.jpg');
      expect(toasts, isEmpty);
      expect(analytics.calls, isEmpty);
      verifyNever(() => store.save(any()));
    });

    test('edge: a second pick while one is open is ignored', () async {
      final pending = Completer<XFile?>();
      final picker = MockImagePicker();
      whenPick(picker).thenAnswer((_) => pending.future);
      final c = build(picker: picker);

      final first = c.pickSelfie();
      expect(await c.pickSelfie(), KycPickResult.cancelled);
      expect(await c.pickAadhaar(ImageSource.gallery), KycPickResult.cancelled);
      await Future<void>.delayed(Duration.zero);
      verifyPicks(picker, 1);

      pending.complete(XFile(photo('cache/selfie.jpg')));
      expect(await first, KycPickResult.added);

      // The guard resets once the first pick is done.
      whenPick(picker).thenAnswer((_) async => null);
      expect(await c.pickSelfie(), KycPickResult.cancelled);
      verifyPicks(picker, 1);
    });

    test(
        'positive: pickImage gets requestFullMetadata false and the front '
        'camera for the selfie', () async {
      final picker = MockImagePicker();
      whenPick(picker).thenAnswer((_) async => null);
      final c = build(picker: picker);

      await c.pickSelfie();
      await c.pickAadhaar(ImageSource.gallery);

      // Exact named arguments, in pick order (captures of named arguments
      // don't keep the call's argument order).
      verifyInOrder([
        () => picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 70,
              maxWidth: 1600,
              preferredCameraDevice: CameraDevice.front,
              requestFullMetadata: false,
            ),
        () => picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 70,
              maxWidth: 1600,
              preferredCameraDevice: CameraDevice.rear,
              requestFullMetadata: false,
            ),
      ]);
    });
  });

  group('kept photos (DS-28)', () {
    test(
        'positive: a picked photo is copied into kyc_draft and saved in the '
        'draft', () async {
      final picked = photo('cache/image_picker_ABC.PNG', const [7, 8, 9]);
      final c = build(picker: pickerReturning(picked));

      expect(await c.pickAadhaar(ImageSource.gallery), KycPickResult.added);

      final kept = c.aadhaarPath.value;
      expect(
        kept,
        matches(RegExp('^${RegExp.escape(keptDir)}/aadhaar_\\d+\\.png\$')),
      );
      expect(File(kept).readAsBytesSync(), [7, 8, 9]);
      expect(lastSaved().aadhaarPath, kept);
      expect(analytics.names, ['kyc_document_captured']);
      expect(analytics.calls.single.parameters, {
        'document': 'aadhaar',
        'source': 'gallery',
      });
      // The picker's own file is left for the OS to clear.
      expect(File(picked).existsSync(), isTrue);
    });

    test('positive: a selfie without an extension is kept as .jpg', () async {
      final c = build(picker: pickerReturning(photo('cache/capture')));

      expect(await c.pickSelfie(), KycPickResult.added);

      expect(
        c.selfiePath.value,
        matches(RegExp('^${RegExp.escape(keptDir)}/selfie_\\d+\\.jpg\$')),
      );
      expect(analytics.calls.single.parameters, {
        'document': 'selfie',
        'source': 'camera',
      });
    });

    test('positive: replacing a photo deletes the previous copy', () async {
      final c = build(picker: pickerReturning(photo('cache/one.jpg')));

      await c.pickAadhaar(ImageSource.gallery);
      final first = c.aadhaarPath.value;
      await c.pickAadhaar(ImageSource.camera);
      final second = c.aadhaarPath.value;

      expect(second, isNot(first));
      expect(File(first).existsSync(), isFalse);
      expect(File(second).existsSync(), isTrue);
    });

    test('edge: a draft path outside kyc_draft is never deleted', () async {
      final outside = photo('cache/old_aadhaar.jpg');
      final c = build(picker: pickerReturning(photo('cache/new.jpg')));
      c.aadhaarPath.value = outside;

      expect(await c.pickAadhaar(ImageSource.gallery), KycPickResult.added);

      expect(File(outside).existsSync(), isTrue);
      expect(c.aadhaarPath.value, startsWith('$keptDir/aadhaar_'));
    });

    test('negative: a failed copy keeps the old photo and says so', () async {
      final c = build(
        picker: pickerReturning(photo('cache/new.jpg')),
        photoDirectory: () async =>
            throw const FileSystemException('no space left'),
      );
      c.aadhaarPath.value = '/kept/aadhaar.jpg';

      expect(await c.pickAadhaar(ImageSource.gallery), KycPickResult.failed);

      expect(c.aadhaarPath.value, '/kept/aadhaar.jpg');
      expect(toasts.single.type, ToastType.error);
      expect(toasts.single.title, isNull);
      expect(
        toasts.single.message,
        "Couldn't save this photo. Please try again.",
      );
      expect(analytics.calls, isEmpty);
      verifyNever(() => store.save(any()));
    });
  });

  group('toast copy', () {
    test('negative: a missing photo asks for both, in plain words', () async {
      stubRegister();
      final c = build();
      c.selfiePath.value = '/s.png';

      await c.onSubmit();

      expect(toasts.single.type, ToastType.warning);
      expect(
        toasts.single.message,
        'Add your Aadhaar photo and a selfie to continue.',
      );
    });

    test("negative: a gallery that won't open says to try again", () async {
      final c = build();

      await c.pickAadhaar(ImageSource.gallery);

      expect(toasts.single.type, ToastType.error);
      expect(toasts.single.title, "Couldn't open gallery");
      expect(toasts.single.message, 'Please try again.');
    });

    test("negative: a camera that won't open says to try again", () async {
      final c = build();

      await c.pickSelfie();

      expect(toasts.single.title, "Couldn't open camera");
      expect(toasts.single.message, 'Please try again.');
    });

    test('positive: a successful submit keeps the submitted message', () async {
      stubRegister();
      when(() => auth.errorMessage).thenReturn(null);
      final c = build();
      c.aadhaarPath.value = photo('a.png');
      c.selfiePath.value = photo('s.png');

      await c.onSubmit();

      expect(toasts.single.type, ToastType.success);
      expect(
        toasts.single.message,
        'Your details were submitted for verification.',
      );
    });
  });
}
