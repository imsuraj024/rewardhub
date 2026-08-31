import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:rewardhub/core/storage/secure_token_store.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({SecureTokenStore? tokenStore})
    : _tokens = tokenStore ?? SecureTokenStore();

  final SecureTokenStore _tokens;
  VoidCallback? onUnauthenticated;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if the request explicitly requires NO auth
    final requiresAuth = options.extra['requiresAuth'] ?? true;

    if (requiresAuth) {
      // Served from the store's in-memory cache after the first read, so this
      // is not a Keystore round trip per request.
      final token = await _tokens.read();

      // If token exists, inject into Authorization header
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // The token the server rejected is worthless, so drop it and let the
    // handler send the user back to login.
    if (err.response?.statusCode == 401) {
      await _tokens.clear();
      onUnauthenticated?.call();
    }
    super.onError(err, handler);
  }
}
