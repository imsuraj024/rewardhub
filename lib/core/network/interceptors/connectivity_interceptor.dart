import 'package:dio/dio.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/core/network/connection_status.dart';
import 'package:rewardhub/core/services/i_connectivity_service.dart';

class ConnectivityInterceptor extends Interceptor {
  final IConnectivityService _service;

  ConnectivityInterceptor(this._service);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    switch (_service.currentStatus) {
      case ConnectionStatus.disconnected:
        handler.reject(
          DioException(
            requestOptions: options,
            error: NoInternetException(reason: 'disconnected'),
            type: DioExceptionType.unknown,
          ),
        );
      case ConnectionStatus.slow:
        options.headers['X-Connection-Quality'] = 'slow';
        handler.next(options);
      case ConnectionStatus.connected:
        handler.next(options);
    }
  }
}
