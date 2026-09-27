import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/core/network/error_handler.dart';
import 'package:rewardhub/core/network/error_messages.dart';

void main() {
  final ro = RequestOptions(path: '/x');

  DioException dio(
    DioExceptionType type, {
    int? statusCode,
    Object? data,
    Object? error,
  }) {
    return DioException(
      requestOptions: ro,
      type: type,
      error: error,
      response: statusCode == null && data == null
          ? null
          : Response(
              requestOptions: ro,
              statusCode: statusCode,
              data: data,
            ),
    );
  }

  group('timeouts', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('positive: $type maps to NetworkException', () {
        final result = ErrorHandler.handle(dio(type));
        expect(result, isA<NetworkException>());
        expect(result.message, ErrorMessages.timeout);
      });
    }
  });

  group('badResponse', () {
    test('positive: 401 maps to UnauthorizedException with message', () {
      final result = ErrorHandler.handle(
        dio(DioExceptionType.badResponse,
            statusCode: 401, data: {'message': 'no token'}),
      );
      expect(result, isA<UnauthorizedException>());
      expect(result.message, 'no token');
    });

    test('positive: 422 maps to ValidationException with statusCode', () {
      final result = ErrorHandler.handle(
        dio(DioExceptionType.badResponse,
            statusCode: 422, data: {'message': 'invalid'}),
      );
      expect(result, isA<ValidationException>());
      expect(result.statusCode, 422);
      expect(result.message, 'invalid');
    });

    test('positive: 400 maps to ValidationException', () {
      final result = ErrorHandler.handle(
        dio(DioExceptionType.badResponse,
            statusCode: 400, data: {'error': 'bad request'}),
      );
      expect(result, isA<ValidationException>());
      expect(result.statusCode, 400);
      // Falls back to the "error" key when "message" is absent.
      expect(result.message, 'bad request');
    });

    test('positive: 500+ maps to ServerException', () {
      final result = ErrorHandler.handle(
        dio(DioExceptionType.badResponse,
            statusCode: 503, data: {'message': 'maintenance'}),
      );
      expect(result, isA<ServerException>());
      expect(result.statusCode, 503);
      expect(result.message, 'maintenance');
    });

    test('edge: other status (404) maps to plain ApiException', () {
      final result = ErrorHandler.handle(
        dio(DioExceptionType.badResponse,
            statusCode: 404, data: {'message': 'not found'}),
      );
      expect(result, isA<ApiException>());
      expect(result, isNot(isA<ValidationException>()));
      expect(result, isNot(isA<ServerException>()));
      expect(result.statusCode, 404);
      expect(result.message, 'not found');
    });

    test('edge: null response data uses default message', () {
      final result = ErrorHandler.handle(
        dio(DioExceptionType.badResponse, statusCode: 404),
      );
      expect(result.message, ErrorMessages.generic);
      expect(result.statusCode, 404);
    });

    test('edge: non-map response data ignored, default message kept', () {
      final result = ErrorHandler.handle(
        dio(DioExceptionType.badResponse,
            statusCode: 500, data: 'raw string body'),
      );
      expect(result, isA<ServerException>());
      expect(result.message, ErrorMessages.generic);
    });

    test('edge: null statusCode falls through to plain ApiException', () {
      final result = ErrorHandler.handle(
        DioException(
          requestOptions: ro,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: ro, data: {'message': 'weird'}),
        ),
      );
      expect(result, isA<ApiException>());
      expect(result.statusCode, isNull);
      expect(result.message, 'weird');
    });
  });

  group('cancel', () {
    test('positive: maps to ApiException with cancelled message', () {
      final result = ErrorHandler.handle(dio(DioExceptionType.cancel));
      expect(result, isA<ApiException>());
      expect(result.message, ErrorMessages.cancelled);
    });
  });

  group('connectionError', () {
    test('positive: maps to NetworkException', () {
      final result = ErrorHandler.handle(dio(DioExceptionType.connectionError));
      expect(result, isA<NetworkException>());
      expect(result.message, ErrorMessages.cannotConnect);
    });
  });

  group('unknown', () {
    test('positive: NoInternetException error is preserved as-is', () {
      final original = NoInternetException(reason: 'airplane');
      final result = ErrorHandler.handle(
        dio(DioExceptionType.unknown, error: original),
      );
      expect(result, same(original));
      expect((result as NoInternetException).reason, 'airplane');
    });

    test('edge: unknown without NoInternetException maps to NetworkException',
        () {
      final result = ErrorHandler.handle(
        dio(DioExceptionType.unknown, error: 'some other error'),
      );
      expect(result, isA<NetworkException>());
      expect(result, isNot(isA<NoInternetException>()));
      expect(result.message, ErrorMessages.cannotConnect);
    });

    test('edge: unknown with null error maps to NetworkException', () {
      final result = ErrorHandler.handle(dio(DioExceptionType.unknown));
      expect(result, isA<NetworkException>());
    });
  });

  group('badCertificate', () {
    test('positive: maps to ApiException with the insecure-connection message',
        () {
      final result = ErrorHandler.handle(dio(DioExceptionType.badCertificate));
      expect(result, isA<ApiException>());
      expect(result.message, ErrorMessages.insecureConnection);
      expect(result.message, isNot(contains('SSL')));
    });
  });

  group('non-Dio errors', () {
    test('negative: arbitrary exception maps to generic ApiException', () {
      final result = ErrorHandler.handle(Exception('boom'));
      expect(result, isA<ApiException>());
      expect(result.message, ErrorMessages.generic);
    });

    test('edge: plain string maps to generic ApiException', () {
      final result = ErrorHandler.handle('just a string');
      expect(result, isA<ApiException>());
      expect(result.message, ErrorMessages.generic);
    });

    test('edge: null maps to generic ApiException', () {
      final result = ErrorHandler.handle(null);
      expect(result, isA<ApiException>());
      expect(result.message, ErrorMessages.generic);
    });
  });
}
