import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/home/data/models/recent_activity_model.dart';
import 'package:rewardhub/features/home/domain/repositories/home_repository.dart';
import 'package:rewardhub/features/home/domain/usecases/get_recent_activities_usecase.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository repository;
  late GetRecentActivitiesUseCase useCase;

  setUp(() {
    repository = MockHomeRepository();
    useCase = GetRecentActivitiesUseCase(repository);
  });

  group('GetRecentActivitiesUseCase.call', () {
    test('positive: forwards token and returns the activity list', () async {
      final activities = [
        RecentActivityModel(
          id: '1',
          type: 'credit',
          points: 10,
          date: DateTime(2024, 1, 1),
        ),
      ];
      when(() => repository.getRecentActivities(token: any(named: 'token')))
          .thenAnswer((_) async => activities);

      final result = await useCase('tok');

      expect(result, same(activities));
      verify(() => repository.getRecentActivities(token: 'tok')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('edge: empty list is passed through', () async {
      when(() => repository.getRecentActivities(token: any(named: 'token')))
          .thenAnswer((_) async => <RecentActivityModel>[]);

      final result = await useCase('tok');

      expect(result, isEmpty);
    });

    test('negative: propagates exceptions from the repository', () async {
      when(() => repository.getRecentActivities(token: any(named: 'token')))
          .thenThrow(ApiException('unauthorized'));

      expect(() => useCase('tok'), throwsA(isA<ApiException>()));
    });
  });
}
