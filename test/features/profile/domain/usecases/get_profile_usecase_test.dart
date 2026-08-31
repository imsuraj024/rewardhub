import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/domain/repositories/profile_repository.dart';
import 'package:rewardhub/features/profile/domain/usecases/get_profile_usecase.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;
  late GetProfileUseCase useCase;

  setUp(() {
    repository = MockProfileRepository();
    useCase = GetProfileUseCase(repository);
  });

  group('GetProfileUseCase.call', () {
    test('positive: forwards token and returns the profile', () async {
      final profile = ProfileModel(
        id: 'u1',
        name: 'Alice',
        mobile: '9876543210',
        points: 100,
      );
      when(() => repository.fetchProfile(token: any(named: 'token')))
          .thenAnswer((_) async => profile);

      final result = await useCase('tok');

      expect(result, same(profile));
      verify(() => repository.fetchProfile(token: 'tok')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('negative: propagates exceptions from the repository', () async {
      when(() => repository.fetchProfile(token: any(named: 'token')))
          .thenThrow(ApiException('not found'));

      expect(() => useCase('tok'), throwsA(isA<ApiException>()));
    });

    test('edge: empty token is forwarded verbatim', () async {
      when(() => repository.fetchProfile(token: any(named: 'token')))
          .thenAnswer((_) async => ProfileModel(
                id: '',
                name: '',
                mobile: '',
                points: 0,
              ));

      await useCase('');

      verify(() => repository.fetchProfile(token: '')).called(1);
    });
  });
}
