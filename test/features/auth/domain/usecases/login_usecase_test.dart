import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/auth/data/models/login_response_model.dart';
import 'package:rewardhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:rewardhub/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  group('LoginUseCase.call', () {
    test('positive: delegates to repository and returns its result', () async {
      final response =
          LoginResponseModel(success: true, isNewUser: false, token: 'jwt');
      when(() => repository.login('9876543210'))
          .thenAnswer((_) async => response);

      final result = await useCase('9876543210');

      expect(result, same(response));
      verify(() => repository.login('9876543210')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('positive: passes the exact phone argument through', () async {
      when(() => repository.login(any())).thenAnswer(
          (_) async => LoginResponseModel(success: true, isNewUser: false));

      await useCase('1234567890');

      verify(() => repository.login('1234567890')).called(1);
    });

    test('negative: propagates exceptions from the repository', () async {
      when(() => repository.login(any()))
          .thenThrow(ApiException('login failed'));

      expect(() => useCase('9876543210'), throwsA(isA<ApiException>()));
    });

    test('edge: empty phone is still forwarded verbatim', () async {
      when(() => repository.login('')).thenAnswer(
          (_) async => LoginResponseModel(success: false, isNewUser: false));

      await useCase('');

      verify(() => repository.login('')).called(1);
    });
  });
}
