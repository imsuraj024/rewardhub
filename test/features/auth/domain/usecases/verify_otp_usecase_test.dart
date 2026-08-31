import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/auth/data/models/otp_response_model.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardhub/features/auth/domain/usecases/verify_otp_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late VerifyOtpUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = VerifyOtpUseCase(repository);
  });

  group('VerifyOtpUseCase.call', () {
    test('positive: verifies then saves the session token', () async {
      when(() => repository.verifyOtp(
            token: any(named: 'token'),
            otp: any(named: 'otp'),
          )).thenAnswer((_) async => OtpResponseModel(success: true));
      when(() => repository.saveSession(any())).thenAnswer((_) async {});

      await useCase(const VerifyOtpParams(token: 'tok', otp: '123456'));

      verify(() => repository.verifyOtp(token: 'tok', otp: '123456')).called(1);
      verify(() => repository.saveSession('tok')).called(1);
    });

    test('positive: verifyOtp is called before saveSession', () async {
      final calls = <String>[];
      when(() => repository.verifyOtp(
            token: any(named: 'token'),
            otp: any(named: 'otp'),
          )).thenAnswer((_) async {
        calls.add('verify');
        return OtpResponseModel(success: true);
      });
      when(() => repository.saveSession(any())).thenAnswer((_) async {
        calls.add('save');
      });

      await useCase(const VerifyOtpParams(token: 'tok', otp: '123456'));

      expect(calls, ['verify', 'save']);
    });

    test('negative: failed verification skips saveSession', () async {
      when(() => repository.verifyOtp(
            token: any(named: 'token'),
            otp: any(named: 'otp'),
          )).thenThrow(ApiException('wrong otp'));

      await expectLater(
        () => useCase(const VerifyOtpParams(token: 'tok', otp: '000000')),
        throwsA(isA<ApiException>()),
      );

      verifyNever(() => repository.saveSession(any()));
    });

    test('edge: saveSession failure propagates', () async {
      when(() => repository.verifyOtp(
            token: any(named: 'token'),
            otp: any(named: 'otp'),
          )).thenAnswer((_) async => OtpResponseModel(success: true));
      when(() => repository.saveSession(any()))
          .thenThrow(Exception('storage error'));

      await expectLater(
        () => useCase(const VerifyOtpParams(token: 'tok', otp: '123456')),
        throwsA(isA<Exception>()),
      );

      verify(() => repository.verifyOtp(token: 'tok', otp: '123456')).called(1);
    });
  });
}
