import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:rewardhub/features/profile/data/models/profile_model.dart';
import 'package:rewardhub/features/profile/data/repositories/profile_repository_impl.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

void main() {
  late MockProfileRemoteDataSource remote;
  late ProfileRepositoryImpl repository;

  setUp(() {
    remote = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(remoteDataSource: remote);
  });

  group('fetchProfile', () {
    test('positive: forwards token and returns the profile', () async {
      final profile = ProfileModel(
        id: 'u1',
        name: 'Alice',
        mobile: '9876543210',
        points: 100,
      );
      when(() => remote.fetchProfile(token: any(named: 'token')))
          .thenAnswer((_) async => profile);

      final result = await repository.fetchProfile(token: 't');

      expect(result, same(profile));
      verify(() => remote.fetchProfile(token: 't')).called(1);
      verifyNoMoreInteractions(remote);
    });

    test('negative: propagates remote errors', () async {
      when(() => remote.fetchProfile(token: any(named: 'token')))
          .thenThrow(ApiException('not found'));

      expect(
        () => repository.fetchProfile(token: 't'),
        throwsA(isA<ApiException>()),
      );
    });

    test('edge: empty token is forwarded verbatim', () async {
      when(() => remote.fetchProfile(token: any(named: 'token')))
          .thenAnswer((_) async =>
              ProfileModel(id: '', name: '', mobile: '', points: 0));

      await repository.fetchProfile(token: '');

      verify(() => remote.fetchProfile(token: '')).called(1);
    });
  });
}
