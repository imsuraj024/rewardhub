import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/interceptors/auth_interceptor.dart';
import 'package:rewardhub/core/storage/secure_token_store.dart';

class MockSecureTokenStore extends Mock implements SecureTokenStore {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

/// Flushes pending microtasks so the async (but `void`-returning) interceptor
/// callbacks complete before assertions run.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockSecureTokenStore tokens;
  late AuthInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/x'));
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '/x')),
    );
  });

  setUp(() {
    tokens = MockSecureTokenStore();
    interceptor = AuthInterceptor(tokenStore: tokens);
  });

  group('onRequest', () {
    test('positive: injects Bearer header when a token exists', () async {
      when(() => tokens.read()).thenAnswer((_) async => 'jwt-123');
      final options = RequestOptions(path: '/secure');
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);
      await settle();

      expect(options.headers['Authorization'], 'Bearer jwt-123');
      verify(() => handler.next(options)).called(1);
    });

    test('edge: no header set when token is null', () async {
      when(() => tokens.read()).thenAnswer((_) async => null);
      final options = RequestOptions(path: '/secure');
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);
      await settle();

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });

    test('edge: no header set when token is empty', () async {
      when(() => tokens.read()).thenAnswer((_) async => '');
      final options = RequestOptions(path: '/secure');
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);
      await settle();

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });

    test('negative: skips token read when requiresAuth is false', () async {
      final options = RequestOptions(
        path: '/public',
        extra: {'requiresAuth': false},
      );
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);
      await settle();

      verifyNever(() => tokens.read());
      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });

    test('positive: reads token when requiresAuth explicitly true', () async {
      when(() => tokens.read()).thenAnswer((_) async => 'jwt');
      final options = RequestOptions(
        path: '/secure',
        extra: {'requiresAuth': true},
      );
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);
      await settle();

      verify(() => tokens.read()).called(1);
      expect(options.headers['Authorization'], 'Bearer jwt');
    });
  });

  group('onError', () {
    test('positive: 401 clears token and invokes onUnauthenticated', () async {
      when(() => tokens.clear()).thenAnswer((_) async {});
      var unauthenticated = false;
      interceptor.onUnauthenticated = () => unauthenticated = true;

      final err = DioException(
        requestOptions: RequestOptions(path: '/secure'),
        response: Response(
          requestOptions: RequestOptions(path: '/secure'),
          statusCode: 401,
        ),
      );
      final handler = MockErrorInterceptorHandler();

      interceptor.onError(err, handler);
      await settle();

      verify(() => tokens.clear()).called(1);
      expect(unauthenticated, isTrue);
      verify(() => handler.next(err)).called(1);
    });

    test('edge: 401 with no onUnauthenticated callback still clears token',
        () async {
      when(() => tokens.clear()).thenAnswer((_) async {});
      final err = DioException(
        requestOptions: RequestOptions(path: '/secure'),
        response: Response(
          requestOptions: RequestOptions(path: '/secure'),
          statusCode: 401,
        ),
      );
      final handler = MockErrorInterceptorHandler();

      interceptor.onError(err, handler);
      await settle();

      verify(() => tokens.clear()).called(1);
      verify(() => handler.next(err)).called(1);
    });

    test('negative: non-401 does not clear token or notify', () async {
      var unauthenticated = false;
      interceptor.onUnauthenticated = () => unauthenticated = true;

      final err = DioException(
        requestOptions: RequestOptions(path: '/secure'),
        response: Response(
          requestOptions: RequestOptions(path: '/secure'),
          statusCode: 500,
        ),
      );
      final handler = MockErrorInterceptorHandler();

      interceptor.onError(err, handler);
      await settle();

      verifyNever(() => tokens.clear());
      expect(unauthenticated, isFalse);
      verify(() => handler.next(err)).called(1);
    });

    test('edge: error without response forwards without clearing', () async {
      final err = DioException(requestOptions: RequestOptions(path: '/x'));
      final handler = MockErrorInterceptorHandler();

      interceptor.onError(err, handler);
      await settle();

      verifyNever(() => tokens.clear());
      verify(() => handler.next(err)).called(1);
    });
  });
}
