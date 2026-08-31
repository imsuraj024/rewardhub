import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/home/data/datasources/home_remote_data_source.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/data/repositories/home_repository_impl.dart';

class MockHomeRemoteDataSource extends Mock implements HomeRemoteDataSource {}

void main() {
  late MockHomeRemoteDataSource remote;
  late HomeRepositoryImpl repository;

  setUp(() {
    remote = MockHomeRemoteDataSource();
    repository = HomeRepositoryImpl(remoteDataSource: remote);
  });

  group('getRecentActivities', () {
    test('positive: forwards token and returns the list', () async {
      final activities = [
        RecentActivityModel(
          id: '1',
          type: 'credit',
          points: 5,
          date: DateTime(2024, 1, 1),
        ),
      ];
      when(() => remote.getRecentActivities(token: any(named: 'token')))
          .thenAnswer((_) async => activities);

      final result = await repository.getRecentActivities(token: 't');

      expect(result, same(activities));
      verify(() => remote.getRecentActivities(token: 't')).called(1);
      verifyNoMoreInteractions(remote);
    });

    test('edge: empty list is passed through', () async {
      when(() => remote.getRecentActivities(token: any(named: 'token')))
          .thenAnswer((_) async => <RecentActivityModel>[]);

      final result = await repository.getRecentActivities(token: 't');

      expect(result, isEmpty);
    });

    test('negative: propagates remote errors', () async {
      when(() => remote.getRecentActivities(token: any(named: 'token')))
          .thenThrow(ApiException('failed'));

      expect(
        () => repository.getRecentActivities(token: 't'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
