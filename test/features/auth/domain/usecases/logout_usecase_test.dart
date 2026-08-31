import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardhub/features/auth/domain/usecases/logout_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LogoutUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LogoutUseCase(repository);
  });

  group('LogoutUseCase.call', () {
    test('positive: delegates to repository.clearSession', () async {
      when(() => repository.clearSession()).thenAnswer((_) async {});

      await useCase(const NoParams());

      verify(() => repository.clearSession()).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('negative: propagates exceptions from the repository', () async {
      when(() => repository.clearSession()).thenThrow(Exception('clear failed'));

      expect(() => useCase(const NoParams()), throwsA(isA<Exception>()));
    });

    test('edge: completes normally (void) on success', () async {
      when(() => repository.clearSession()).thenAnswer((_) async {});

      await expectLater(useCase(const NoParams()), completes);
    });
  });
}
