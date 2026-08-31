import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/storage/secure_token_store.dart';
import 'package:rewardhub/features/auth/data/datasources/auth_local_data_source.dart';

class MockSecureTokenStore extends Mock implements SecureTokenStore {}

void main() {
  late MockSecureTokenStore tokens;
  late AuthLocalDataSourceImpl dataSource;

  setUp(() {
    tokens = MockSecureTokenStore();
    dataSource = AuthLocalDataSourceImpl(tokenStore: tokens);
  });

  group('readToken', () {
    test('positive: delegates to the token store', () async {
      when(() => tokens.read()).thenAnswer((_) async => 'jwt');

      expect(await dataSource.readToken(), 'jwt');
      verify(() => tokens.read()).called(1);
    });

    test('edge: null token propagated', () async {
      when(() => tokens.read()).thenAnswer((_) async => null);

      expect(await dataSource.readToken(), isNull);
    });
  });

  group('readIsLoggedIn', () {
    test('positive: true when a non-empty token exists', () async {
      when(() => tokens.read()).thenAnswer((_) async => 'jwt');

      expect(await dataSource.readIsLoggedIn(), isTrue);
    });

    test('negative: false when token is null', () async {
      when(() => tokens.read()).thenAnswer((_) async => null);

      expect(await dataSource.readIsLoggedIn(), isFalse);
    });

    test('edge: false when token is empty string', () async {
      when(() => tokens.read()).thenAnswer((_) async => '');

      expect(await dataSource.readIsLoggedIn(), isFalse);
    });
  });

  group('saveSession', () {
    test('positive: writes the token to the store', () async {
      when(() => tokens.write(any())).thenAnswer((_) async {});

      await dataSource.saveSession('jwt');

      verify(() => tokens.write('jwt')).called(1);
    });

    test('edge: empty token still delegated to write', () async {
      when(() => tokens.write(any())).thenAnswer((_) async {});

      await dataSource.saveSession('');

      verify(() => tokens.write('')).called(1);
    });
  });

  group('clearSession', () {
    test('positive: clears the token store', () async {
      when(() => tokens.clear()).thenAnswer((_) async {});

      await dataSource.clearSession();

      verify(() => tokens.clear()).called(1);
    });
  });
}
