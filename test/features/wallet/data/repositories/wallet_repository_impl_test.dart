import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:rewardhub/features/wallet/data/models/raise_request_response_model.dart';
import 'package:rewardhub/features/wallet/data/repositories/wallet_repository_impl.dart';

class MockWalletRemoteDataSource extends Mock
    implements WalletRemoteDataSource {}

void main() {
  late MockWalletRemoteDataSource remote;
  late WalletRepositoryImpl repository;

  setUp(() {
    remote = MockWalletRemoteDataSource();
    repository = WalletRepositoryImpl(remoteDataSource: remote);
  });

  group('raiseRequest', () {
    test('positive: forwards token and returns the result', () async {
      const response =
          RaiseRequestResponseModel(success: true, message: 'raised');
      when(() => remote.raiseRequest(token: any(named: 'token')))
          .thenAnswer((_) async => response);

      final result = await repository.raiseRequest(token: 't');

      expect(result, same(response));
      verify(() => remote.raiseRequest(token: 't')).called(1);
      verifyNoMoreInteractions(remote);
    });

    test('negative: propagates remote errors', () async {
      when(() => remote.raiseRequest(token: any(named: 'token')))
          .thenThrow(ApiException('failed'));

      expect(
        () => repository.raiseRequest(token: 't'),
        throwsA(isA<ApiException>()),
      );
    });

    test('edge: empty token is forwarded verbatim', () async {
      when(() => remote.raiseRequest(token: any(named: 'token')))
          .thenAnswer((_) async =>
              const RaiseRequestResponseModel(success: false));

      await repository.raiseRequest(token: '');

      verify(() => remote.raiseRequest(token: '')).called(1);
    });
  });
}
