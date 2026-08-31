import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/network/api_endpoints.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/profile/data/datasources/profile_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late ProfileRemoteDataSourceImpl dataSource;

  setUp(() {
    api = MockApiClient();
    dataSource = ProfileRemoteDataSourceImpl(apiClient: api);
  });

  group('fetchProfile', () {
    test('positive: maps JSON to the profile model', () async {
      when(() => api.post(ApiEndpoints.userProfile, data: any(named: 'data')))
          .thenAnswer((_) async => {
                'id': 'u1',
                'name': 'Alice',
                'mobile': '9876543210',
                'points': 100,
              });

      final result = await dataSource.fetchProfile(token: 't');

      expect(result.id, 'u1');
      expect(result.name, 'Alice');
      expect(result.mobile, '9876543210');
      expect(result.points, 100);
    });

    test('positive: sends token in the request body', () async {
      Map<String, dynamic>? sent;
      when(() => api.post(ApiEndpoints.userProfile, data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as Map<String, dynamic>;
        return {'id': '1', 'name': 'A', 'mobile': '2', 'points': 0};
      });

      await dataSource.fetchProfile(token: 'tok');

      expect(sent!['token'], 'tok');
    });

    test('edge: empty JSON maps to default profile values', () async {
      when(() => api.post(ApiEndpoints.userProfile, data: any(named: 'data')))
          .thenAnswer((_) async => <String, dynamic>{});

      final result = await dataSource.fetchProfile(token: 't');

      expect(result.id, '');
      expect(result.name, '');
      expect(result.mobile, '');
      expect(result.points, 0);
    });

    test('negative: propagates transport errors', () async {
      when(() => api.post(ApiEndpoints.userProfile, data: any(named: 'data')))
          .thenThrow(NetworkException('offline'));

      expect(
        () => dataSource.fetchProfile(token: 't'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
