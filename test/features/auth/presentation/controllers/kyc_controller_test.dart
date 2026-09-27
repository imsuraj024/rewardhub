import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/features/auth/data/datasources/registration_draft_store.dart';
import 'package:rewardhub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:rewardhub/features/auth/presentation/controllers/kyc_controller.dart';

import '../../../../helpers/harness.dart';
import '../../../../helpers/recording_analytics.dart';

class MockAuthController extends Mock implements AuthController {}

class MockRegistrationDraftStore extends Mock
    implements RegistrationDraftStore {}

void main() {
  late AnalyticsHarness analytics;
  late MockAuthController auth;
  late MockRegistrationDraftStore store;
  late List<RecordedToast> toasts;

  setUpAll(() {
    registerFallbackValue(const RegistrationDraft());
  });

  setUp(() {
    analytics = AnalyticsHarness();
    toasts = installGetTestHarness();
    auth = MockAuthController();
    store = MockRegistrationDraftStore();
    when(() => store.read()).thenAnswer((_) async => const RegistrationDraft());
    when(() => store.save(any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
  });

  tearDown(resetGet);

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

  KycController build() => KycController(store, auth, analytics.analytics);

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
      when(() => store.read()).thenAnswer(
        (_) async => const RegistrationDraft(
          aadhaarPath: '/a.png',
          selfiePath: '/s.png',
        ),
      );
      final c = build();

      c.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(c.aadhaarPath.value, '/a.png');
      expect(c.selfiePath.value, '/s.png');
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
      c.aadhaarPath.value = '/a.png';
      c.selfiePath.value = '/s.png';

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
      c.aadhaarPath.value = '/a.png';
      c.selfiePath.value = '/s.png';

      await c.onSubmit();

      verify(() => store.save(any())).called(1);
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

    test('negative: a blocked gallery says where to allow access', () async {
      final c = build();

      await c.pickAadhaar(ImageSource.gallery);

      expect(toasts.single.type, ToastType.error);
      expect(toasts.single.title, "Couldn't open gallery");
      expect(
        toasts.single.message,
        'Allow access in your phone settings, then try again.',
      );
    });

    test('negative: a blocked camera names the camera', () async {
      final c = build();

      await c.pickSelfie();

      expect(toasts.single.title, "Couldn't open camera");
      expect(
        toasts.single.message,
        'Allow access in your phone settings, then try again.',
      );
    });

    test('positive: a successful submit keeps the submitted message',
        () async {
      stubRegister();
      when(() => auth.errorMessage).thenReturn(null);
      final c = build();
      c.aadhaarPath.value = '/a.png';
      c.selfiePath.value = '/s.png';

      await c.onSubmit();

      expect(toasts.single.type, ToastType.success);
      expect(
        toasts.single.message,
        'Your details were submitted for verification.',
      );
    });
  });
}
