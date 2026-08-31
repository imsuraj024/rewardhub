import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_endpoints.dart';
import 'error_handler.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import '../services/connectivity_service.dart';
import '../utils/alice_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _authInterceptor = AuthInterceptor();
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final aliceInterceptor = aliceRef?.getDioInterceptor();
    if (aliceInterceptor != null) {
      _dio.interceptors.add(aliceInterceptor);
    }

    // Attach interceptors
    _dio.interceptors.addAll([
      ConnectivityInterceptor(ConnectivityService()),
      _authInterceptor,
      if (kDebugMode) LoggingInterceptor(), // Only log in debug builds
    ]);
  }

  /// Sets a global callback that is triggered whenever a 401 Unauthorized hits.
  /// Typically used to force the Router to redirect to the login screen.
  void setUnauthenticatedHandler(VoidCallback handler) {
    _authInterceptor.onUnauthenticated = handler;
  }

  /// Perform a GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Perform a POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Perform a PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Perform a DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Perform a PATCH request
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
