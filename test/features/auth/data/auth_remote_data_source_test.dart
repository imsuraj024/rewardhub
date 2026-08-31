import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/network/api_endpoints.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/auth/data/datasources/auth_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    api = MockApiClient();
    dataSource = AuthRemoteDataSourceImpl(apiClient: api);
  });

  group('login', () {
    test('positive: maps JSON to model', () async {
      when(() => api.post(ApiEndpoints.login, data: any(named: 'data')))
          .thenAnswer((_) async =>
              {'success': true, 'isNewUser': false, 'token': 'jwt'});

      final result = await dataSource.login('9876543210');

      expect(result.success, isTrue);
      expect(result.token, 'jwt');
    });

    test('positive: new-user response passes through', () async {
      when(() => api.post(ApiEndpoints.login, data: any(named: 'data')))
          .thenAnswer((_) async => {'success': false, 'isNewUser': true});

      final result = await dataSource.login('9876543210');

      expect(result.isNewUser, isTrue);
    });

    test('negative: business failure throws ApiException', () async {
      when(() => api.post(ApiEndpoints.login, data: any(named: 'data')))
          .thenAnswer((_) async =>
              {'success': false, 'isNewUser': false, 'message': 'no user'});

      expect(
        () => dataSource.login('9876543210'),
        throwsA(isA<ApiException>()),
      );
    });

    test('negative: propagates transport errors', () async {
      when(() => api.post(ApiEndpoints.login, data: any(named: 'data')))
          .thenThrow(NetworkException('offline'));

      expect(
        () => dataSource.login('9876543210'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('register', () {
    test('positive: success returns model with token', () async {
      when(() => api.post(ApiEndpoints.register, data: any(named: 'data')))
          .thenAnswer((_) async => {'success': true, 'token': 'jwt'});

      final result = await dataSource.register(name: 'A', phone: '1');

      expect(result.success, isTrue);
      expect(result.token, 'jwt');
    });

    test('edge: empty optional fields sent, still succeeds', () async {
      FormData? sent;
      when(() => api.post(ApiEndpoints.register, data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as FormData;
        return {'success': true, 'token': 'jwt'};
      });

      await dataSource.register(name: 'A', phone: '1', accountNumber: '   ');

      final fields = {for (final f in sent!.fields) f.key: f.value};
      expect(fields['AccountNumber'], 'NA');
      expect(fields['Name'], 'A');
    });

    test('negative: unsuccessful register throws', () async {
      when(() => api.post(ApiEndpoints.register, data: any(named: 'data')))
          .thenAnswer((_) async => {'success': false, 'message': 'exists'});

      expect(
        () => dataSource.register(name: 'A', phone: '1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('verifyOtp', () {
    test('positive: success returns model', () async {
      when(() => api.post(ApiEndpoints.verifyOtp, data: any(named: 'data')))
          .thenAnswer((_) async => {'success': true});

      final result = await dataSource.verifyOtp(token: 't', otp: '123456');

      expect(result.success, isTrue);
    });

    test('negative: failure throws ApiException', () async {
      when(() => api.post(ApiEndpoints.verifyOtp, data: any(named: 'data')))
          .thenAnswer((_) async => {'success': false, 'message': 'wrong'});

      expect(
        () => dataSource.verifyOtp(token: 't', otp: '000000'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('deleteAccount', () {
    test('positive: sends token to delete account endpoint', () async {
      when(() => api.post(ApiEndpoints.deleteAccount, data: any(named: 'data')))
          .thenAnswer((_) async => {'success': true});

      await dataSource.deleteAccount('test-token');

      verify(
        () => api.post(ApiEndpoints.deleteAccount, data: {'token': 'test-token'}),
      ).called(1);
    });

    test('negative: failure response throws ApiException', () async {
      when(() => api.post(ApiEndpoints.deleteAccount, data: any(named: 'data')))
          .thenAnswer((_) async => {'success': false, 'message': 'deletion failed'});

      expect(
        () => dataSource.deleteAccount('test-token'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
