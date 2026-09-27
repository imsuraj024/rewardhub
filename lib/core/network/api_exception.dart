import 'error_messages.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (statusCode: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException([super.message = ErrorMessages.cannotConnect]);
}

class ServerException extends ApiException {
  ServerException([super.message = ErrorMessages.generic, super.statusCode]);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = ErrorMessages.sessionExpired])
    : super(message, 401);
}

class ValidationException extends ApiException {
  ValidationException([
    super.message = ErrorMessages.invalidInput,
    super.statusCode,
  ]);
}

class NoInternetException extends NetworkException {
  final String reason;

  NoInternetException({this.reason = 'disconnected'})
      : super('No internet connection ($reason)');
}
