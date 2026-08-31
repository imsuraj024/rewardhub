class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (statusCode: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException([super.message = 'No internet connection']);
}

class ServerException extends ApiException {
  ServerException([super.message = 'Internal server error', super.statusCode]);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Unauthorized accessor'])
    : super(message, 401);
}

class ValidationException extends ApiException {
  ValidationException([super.message = 'Validation failed', super.statusCode]);
}

class NoInternetException extends NetworkException {
  final String reason;

  NoInternetException({this.reason = 'disconnected'})
      : super('No internet connection ($reason)');
}
