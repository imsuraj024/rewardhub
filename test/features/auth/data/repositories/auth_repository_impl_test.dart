import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:rewardhub/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:rewardhub/features/auth/data/models/login_response_model.dart';
import 'package:rewardhub/features/auth/data/models/otp_response_model.dart';
import 'package:rewardhub/features/auth/data/models/register_response_model.dart';
import 'package:rewardhub/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockAuthRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = MockAuthRemoteDataSource();
    local = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
  });

  group('login', () {
    test('positive: delegates to the remote data source', () async {
      final response =
          LoginResponseModel(success: true, isNewUser: false, token: 'jwt');
      when(() => remote.login(any())).thenAnswer((_) async => response);

      final result = await repository.login('9876543210');

      expect(result, same(response));
      verify(() => remote.login('9876543210')).called(1);
    });

    test('negative: propagates remote errors', () async {
      when(() => remote.login(any())).thenThrow(ApiException('failed'));

      expect(() => repository.login('1'), throwsA(isA<ApiException>()));
    });
  });

  group('register', () {
    test('positive: forwards all params to remote', () async {
      final response = RegisterResponseModel(success: true, token: 'jwt');
      when(
        () => remote.register(
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

      final result = await repository.register(
        name: 'Alice',
        phone: '9876543210',
        referralCode: 'REF',
      );

      expect(result, same(response));
      verify(
        () => remote.register(
          name: 'Alice',
          phone: '9876543210',
          referralCode: 'REF',
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

    test('negative: propagates remote errors', () async {
      when(
        () => remote.register(
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

      expect(
        () => repository.register(name: 'A', phone: '1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('verifyOtp', () {
    test('positive: delegates to remote', () async {
      final response = OtpResponseModel(success: true);
      when(() => remote.verifyOtp(
            token: any(named: 'token'),
            otp: any(named: 'otp'),
          )).thenAnswer((_) async => response);

      final result = await repository.verifyOtp(token: 't', otp: '123456');

      expect(result, same(response));
      verify(() => remote.verifyOtp(token: 't', otp: '123456')).called(1);
    });

    test('negative: propagates remote errors', () async {
      when(() => remote.verifyOtp(
            token: any(named: 'token'),
            otp: any(named: 'otp'),
          )).thenThrow(ApiException('wrong'));

      expect(
        () => repository.verifyOtp(token: 't', otp: '0'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('saveSession', () {
    test('positive: delegates to local data source', () async {
      when(() => local.saveSession(any())).thenAnswer((_) async {});

      await repository.saveSession('jwt');

      verify(() => local.saveSession('jwt')).called(1);
    });
  });

  group('clearSession', () {
    test('positive: delegates to local data source', () async {
      when(() => local.clearSession()).thenAnswer((_) async {});

      await repository.clearSession();

      verify(() => local.clearSession()).called(1);
    });
  });

  group('restoreSession', () {
    test('positive: returns token when logged in with a valid token',
        () async {
      when(() => local.readIsLoggedIn()).thenAnswer((_) async => true);
      when(() => local.readToken()).thenAnswer((_) async => 'jwt');

      final result = await repository.restoreSession();

      expect(result, 'jwt');
      verify(() => local.readIsLoggedIn()).called(1);
      verify(() => local.readToken()).called(1);
    });

    test('negative: returns null when not logged in (token not read)',
        () async {
      when(() => local.readIsLoggedIn()).thenAnswer((_) async => false);

      final result = await repository.restoreSession();

      expect(result, isNull);
      verify(() => local.readIsLoggedIn()).called(1);
      verifyNever(() => local.readToken());
    });

    test('edge: logged in but null token returns null', () async {
      when(() => local.readIsLoggedIn()).thenAnswer((_) async => true);
      when(() => local.readToken()).thenAnswer((_) async => null);

      final result = await repository.restoreSession();

      expect(result, isNull);
    });

    test('edge: logged in but empty token returns null', () async {
      when(() => local.readIsLoggedIn()).thenAnswer((_) async => true);
      when(() => local.readToken()).thenAnswer((_) async => '');

      final result = await repository.restoreSession();

      expect(result, isNull);
    });
  });
}
