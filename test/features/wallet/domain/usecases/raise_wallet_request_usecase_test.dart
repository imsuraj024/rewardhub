import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/wallet/data/models/raise_request_response_model.dart';
import 'package:rewardhub/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:rewardhub/features/wallet/domain/usecases/raise_wallet_request_usecase.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockWalletRepository repository;
  late RaiseWalletRequestUseCase useCase;

  setUp(() {
    repository = MockWalletRepository();
    useCase = RaiseWalletRequestUseCase(repository);
  });

  group('RaiseWalletRequestUseCase.call', () {
    test('positive: forwards token and returns the result', () async {
      const response = RaiseRequestResponseModel(
        success: true,
        message: 'raised',
      );
      when(() => repository.raiseRequest(token: any(named: 'token')))
          .thenAnswer((_) async => response);

      final result = await useCase('tok');

      expect(result, same(response));
      verify(() => repository.raiseRequest(token: 'tok')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('negative: propagates business failures', () async {
      when(() => repository.raiseRequest(token: any(named: 'token')))
          .thenThrow(ApiException('insufficient balance'));

      expect(() => useCase('tok'), throwsA(isA<ApiException>()));
    });

    test('edge: empty token is forwarded verbatim', () async {
      when(() => repository.raiseRequest(token: any(named: 'token')))
          .thenAnswer((_) async =>
              const RaiseRequestResponseModel(success: false));

      await useCase('');

      verify(() => repository.raiseRequest(token: '')).called(1);
    });
  });
}
