import 'package:dio/dio.dart';
import 'api_exception.dart';
import 'error_messages.dart';

class ErrorHandler {
  static ApiException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkException(ErrorMessages.timeout);
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          String message = ErrorMessages.generic;
          if (responseData != null && responseData is Map<String, dynamic>) {
            message =
                responseData['message'] ?? responseData['error'] ?? message;
          }

          if (statusCode == 401) {
            return UnauthorizedException(message);
          } else if (statusCode == 422 || statusCode == 400) {
            return ValidationException(message, statusCode);
          } else if (statusCode != null && statusCode >= 500) {
            return ServerException(message, statusCode);
          } else {
            return ApiException(message, statusCode);
          }
        case DioExceptionType.cancel:
          return ApiException(ErrorMessages.cancelled);
        case DioExceptionType.connectionError:
          return NetworkException(ErrorMessages.cannotConnect);
        case DioExceptionType.unknown:
          // Preserve NoInternetException thrown by ConnectivityInterceptor
          if (error.error is NoInternetException) {
            return error.error as NoInternetException;
          }
          return NetworkException(ErrorMessages.cannotConnect);
        case DioExceptionType.badCertificate:
          return ApiException(ErrorMessages.insecureConnection);
      }
    } else {
      return ApiException(ErrorMessages.generic);
    }
  }
}
