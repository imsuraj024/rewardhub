import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/auth/data/models/register_response_model.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardhub/features/auth/domain/usecases/register_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late RegisterUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = RegisterUseCase(repository);
  });

  group('RegisterUseCase.call', () {
    test('positive: forwards every param and returns the result', () async {
      final response = RegisterResponseModel(success: true, token: 'jwt');
      when(
        () => repository.register(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          referralCode: any(named: 'referralCode'),
          bankName: any(named: 'bankName'),
          accountNumber: any(named: 'accountNumber'),
          ifscCode: any(named: 'ifscCode'),
          bankAddress: any(named: 'bankAddress'),
          upiId: any(named: 'upiId'),
          selfiePhotoPath: any(named: 'selfiePhotoPath'),
          aadharPhotoPath: any(named: 'aadharPhotoPath'),
        ),
      ).thenAnswer((_) async => response);

      const params = RegisterParams(
        name: 'Alice',
        phone: '9876543210',
        referralCode: 'REF1',
        bankName: 'Bank',
        accountNumber: '000111',
        ifscCode: 'IFSC0001',
        bankAddress: 'Street',
        upiId: 'alice@upi',
        selfiePhotoPath: '/tmp/selfie.jpg',
        aadharPhotoPath: '/tmp/aadhar.jpg',
      );

      final result = await useCase(params);

      expect(result, same(response));
      verify(
        () => repository.register(
          name: 'Alice',
          phone: '9876543210',
          referralCode: 'REF1',
          bankName: 'Bank',
          accountNumber: '000111',
          ifscCode: 'IFSC0001',
          bankAddress: 'Street',
          upiId: 'alice@upi',
          selfiePhotoPath: '/tmp/selfie.jpg',
          aadharPhotoPath: '/tmp/aadhar.jpg',
        ),
      ).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('edge: null optional params are forwarded as null', () async {
      when(
        () => repository.register(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          referralCode: any(named: 'referralCode'),
          bankName: any(named: 'bankName'),
          accountNumber: any(named: 'accountNumber'),
          ifscCode: any(named: 'ifscCode'),
          bankAddress: any(named: 'bankAddress'),
          upiId: any(named: 'upiId'),
          selfiePhotoPath: any(named: 'selfiePhotoPath'),
          aadharPhotoPath: any(named: 'aadharPhotoPath'),
        ),
      ).thenAnswer((_) async => RegisterResponseModel(success: true));

      const params = RegisterParams(name: 'Bob', phone: '1');

      await useCase(params);

      verify(
        () => repository.register(
          name: 'Bob',
          phone: '1',
          referralCode: null,
          bankName: null,
          accountNumber: null,
          ifscCode: null,
          bankAddress: null,
          upiId: null,
          selfiePhotoPath: null,
          aadharPhotoPath: null,
        ),
      ).called(1);
    });

    test('negative: propagates exceptions from the repository', () async {
      when(
        () => repository.register(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          referralCode: any(named: 'referralCode'),
          bankName: any(named: 'bankName'),
          accountNumber: any(named: 'accountNumber'),
          ifscCode: any(named: 'ifscCode'),
          bankAddress: any(named: 'bankAddress'),
          upiId: any(named: 'upiId'),
          selfiePhotoPath: any(named: 'selfiePhotoPath'),
          aadharPhotoPath: any(named: 'aadharPhotoPath'),
        ),
      ).thenThrow(ApiException('exists'));

      const params = RegisterParams(name: 'Bob', phone: '1');

      expect(() => useCase(params), throwsA(isA<ApiException>()));
    });
  });
}
