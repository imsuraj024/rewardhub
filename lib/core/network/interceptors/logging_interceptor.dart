import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('➡️ REQUEST[${options.method}] => PATH: ${options.path}');
      debugPrint('➡️ HEADERS: ${options.headers}');
      if (options.queryParameters.isNotEmpty) debugPrint('➡️ QUERY: ${options.queryParameters}');
      if (options.data != null) debugPrint('➡️ BODY: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('⬅️ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      debugPrint('⬅️ DATA: ${jsonEncode(response.data)}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      debugPrint('❌ MESSAGE: ${err.message}');
    }
    super.onError(err, handler);
  }
}
