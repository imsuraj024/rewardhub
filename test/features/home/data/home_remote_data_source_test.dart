import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/network/api_endpoints.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/home/data/datasources/home_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late HomeRemoteDataSourceImpl dataSource;

  setUp(() {
    api = MockApiClient();
    dataSource = HomeRemoteDataSourceImpl(apiClient: api);
  });

  group('getRecentActivities', () {
    test('positive: maps the transactions list to models', () async {
      when(() => api.post(ApiEndpoints.transactions, data: any(named: 'data')))
          .thenAnswer((_) async => {
                'transactions': [
                  {
                    'id': 't1',
                    'type': 'credit',
                    'points': 10,
                    'date': '2024-01-01',
                  },
                  {
                    'id': 't2',
                    'type': 'debit',
                    'points': 5,
                    'date': '2024-01-02',
                  },
                ],
              });

      final result = await dataSource.getRecentActivities(token: 't');

      expect(result, hasLength(2));
      expect(result.first.id, 't1');
      expect(result.first.isCredit, isTrue);
      expect(result.last.type, 'debit');
    });

    test('positive: sends token in the request body', () async {
      Map<String, dynamic>? sent;
      when(() => api.post(ApiEndpoints.transactions, data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as Map<String, dynamic>;
        return {'transactions': <dynamic>[]};
      });

      await dataSource.getRecentActivities(token: 'tok');

      expect(sent!['token'], 'tok');
    });

    test('edge: missing transactions key yields an empty list', () async {
      when(() => api.post(ApiEndpoints.transactions, data: any(named: 'data')))
          .thenAnswer((_) async => <String, dynamic>{});

      final result = await dataSource.getRecentActivities(token: 't');

      expect(result, isEmpty);
    });

    test('edge: null transactions value yields an empty list', () async {
      when(() => api.post(ApiEndpoints.transactions, data: any(named: 'data')))
          .thenAnswer((_) async => {'transactions': null});

      final result = await dataSource.getRecentActivities(token: 't');

      expect(result, isEmpty);
    });

    test('negative: propagates transport errors', () async {
      when(() => api.post(ApiEndpoints.transactions, data: any(named: 'data')))
          .thenThrow(NetworkException('offline'));

      expect(
        () => dataSource.getRecentActivities(token: 't'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
