import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/network/api_endpoints.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/wallet/data/datasources/wallet_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late WalletRemoteDataSourceImpl dataSource;

  setUp(() {
    api = MockApiClient();
    dataSource = WalletRemoteDataSourceImpl(apiClient: api);
  });

  group('raiseRequest', () {
    test('positive: maps a successful response to the model', () async {
      when(() =>
              api.post(ApiEndpoints.raiseWalletRequest, data: any(named: 'data')))
          .thenAnswer((_) async => {'Success': true, 'Message': 'raised'});

      final result = await dataSource.raiseRequest(token: 't');

      expect(result.success, isTrue);
      expect(result.message, 'raised');
    });

    test('positive: sends token in the request body', () async {
      Map<String, dynamic>? sent;
      when(() =>
              api.post(ApiEndpoints.raiseWalletRequest, data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as Map<String, dynamic>;
        return {'Success': true};
      });

      await dataSource.raiseRequest(token: 'tok');

      expect(sent!['token'], 'tok');
    });

    test('negative: business failure throws ApiException', () async {
      when(() =>
              api.post(ApiEndpoints.raiseWalletRequest, data: any(named: 'data')))
          .thenAnswer(
              (_) async => {'Success': false, 'Message': 'insufficient'});

      expect(
        () => dataSource.raiseRequest(token: 't'),
        throwsA(isA<ApiException>()),
      );
    });

    test('negative: propagates transport errors', () async {
      when(() =>
              api.post(ApiEndpoints.raiseWalletRequest, data: any(named: 'data')))
          .thenThrow(NetworkException('offline'));

      expect(
        () => dataSource.raiseRequest(token: 't'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('edge: empty JSON defaults success=false and throws', () async {
      when(() =>
              api.post(ApiEndpoints.raiseWalletRequest, data: any(named: 'data')))
          .thenAnswer((_) async => <String, dynamic>{});

      expect(
        () => dataSource.raiseRequest(token: 't'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
