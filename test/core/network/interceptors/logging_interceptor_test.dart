import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/interceptors/logging_interceptor.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockResponseInterceptorHandler extends Mock
    implements ResponseInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late LoggingInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/x'));
    registerFallbackValue(
      Response(requestOptions: RequestOptions(path: '/x')),
    );
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '/x')),
    );
  });

  setUp(() => interceptor = LoggingInterceptor());

  group('onRequest', () {
    test('positive: forwards the request via handler.next', () {
      final options = RequestOptions(
        path: '/x',
        method: 'POST',
        queryParameters: {'q': '1'},
        data: {'body': true},
      );
      final handler = MockRequestInterceptorHandler();

      expect(() => interceptor.onRequest(options, handler), returnsNormally);
      verify(() => handler.next(options)).called(1);
    });

    test('edge: request with no query/body does not throw', () {
      final options = RequestOptions(path: '/x');
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      verify(() => handler.next(options)).called(1);
    });
  });

  group('onResponse', () {
    test('positive: forwards the response via handler.next', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
        data: {'ok': true},
      );
      final handler = MockResponseInterceptorHandler();

      expect(() => interceptor.onResponse(response, handler), returnsNormally);
      verify(() => handler.next(response)).called(1);
    });

    test('edge: null data response does not throw', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 204,
      );
      final handler = MockResponseInterceptorHandler();

      interceptor.onResponse(response, handler);

      verify(() => handler.next(response)).called(1);
    });
  });

  group('onError', () {
    test('negative: forwards the error via handler.next', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
        ),
        message: 'boom',
      );
      final handler = MockErrorInterceptorHandler();

      expect(() => interceptor.onError(err, handler), returnsNormally);
      verify(() => handler.next(err)).called(1);
    });

    test('edge: error without response does not throw', () {
      final err = DioException(requestOptions: RequestOptions(path: '/x'));
      final handler = MockErrorInterceptorHandler();

      interceptor.onError(err, handler);

      verify(() => handler.next(err)).called(1);
    });
  });
}
