import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/core/network/connection_status.dart';
import 'package:rewardhub/core/network/interceptors/connectivity_interceptor.dart';
import 'package:rewardhub/core/services/i_connectivity_service.dart';

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

void main() {
  late MockConnectivityService service;
  late ConnectivityInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/x'));
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '/x')),
    );
  });

  setUp(() {
    service = MockConnectivityService();
    interceptor = ConnectivityInterceptor(service);
  });

  group('onRequest', () {
    test('positive: connected forwards the request unchanged', () {
      when(() => service.currentStatus)
          .thenReturn(ConnectionStatus.connected);
      final options = RequestOptions(path: '/x');
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      verify(() => handler.next(options)).called(1);
      verifyNever(() => handler.reject(any()));
      expect(options.headers.containsKey('X-Connection-Quality'), isFalse);
    });

    test('edge: slow adds quality header and forwards', () {
      when(() => service.currentStatus).thenReturn(ConnectionStatus.slow);
      final options = RequestOptions(path: '/x');
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['X-Connection-Quality'], 'slow');
      verify(() => handler.next(options)).called(1);
      verifyNever(() => handler.reject(any()));
    });

    test('negative: disconnected rejects with NoInternetException', () {
      when(() => service.currentStatus)
          .thenReturn(ConnectionStatus.disconnected);
      final options = RequestOptions(path: '/x');
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      final captured =
          verify(() => handler.reject(captureAny())).captured.single
              as DioException;
      expect(captured.type, DioExceptionType.unknown);
      expect(captured.error, isA<NoInternetException>());
      expect((captured.error as NoInternetException).reason, 'disconnected');
      expect(captured.requestOptions, same(options));
      verifyNever(() => handler.next(any()));
    });
  });
}
