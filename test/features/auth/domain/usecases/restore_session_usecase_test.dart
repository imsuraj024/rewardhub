import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardhub/features/auth/domain/usecases/restore_session_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late RestoreSessionUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = RestoreSessionUseCase(repository);
  });

  group('RestoreSessionUseCase.call', () {
    test('positive: returns the persisted token', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => 'jwt');

      final result = await useCase(const NoParams());

      expect(result, 'jwt');
      verify(() => repository.restoreSession()).called(1);
    });

    test('negative: returns null when there is no session', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);

      final result = await useCase(const NoParams());

      expect(result, isNull);
    });

    test('edge: propagates exceptions from the repository', () async {
      when(() => repository.restoreSession()).thenThrow(Exception('boom'));

      expect(() => useCase(const NoParams()), throwsA(isA<Exception>()));
    });
  });
}
