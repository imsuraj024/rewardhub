import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/network/api_exception.dart';

void main() {
  group('ApiException', () {
    test('positive: stores message and statusCode', () {
      final e = ApiException('boom', 418);
      expect(e.message, 'boom');
      expect(e.statusCode, 418);
    });

    test('edge: statusCode defaults to null when omitted', () {
      final e = ApiException('boom');
      expect(e.statusCode, isNull);
    });

    test('positive: toString includes message and statusCode', () {
      final e = ApiException('boom', 500);
      expect(e.toString(), 'ApiException: boom (statusCode: 500)');
    });

    test('edge: toString renders null statusCode', () {
      final e = ApiException('boom');
      expect(e.toString(), 'ApiException: boom (statusCode: null)');
    });

    test('negative: is an Exception', () {
      expect(ApiException('x'), isA<Exception>());
    });
  });

  group('NetworkException', () {
    test('positive: custom message retained', () {
      expect(NetworkException('offline').message, 'offline');
    });

    test('edge: default message used', () {
      expect(NetworkException().message, 'No internet connection');
    });

    test('positive: is an ApiException', () {
      expect(NetworkException(), isA<ApiException>());
      expect(NetworkException().statusCode, isNull);
    });
  });

  group('ServerException', () {
    test('positive: custom message and status', () {
      final e = ServerException('down', 503);
      expect(e.message, 'down');
      expect(e.statusCode, 503);
    });

    test('edge: default message and null status', () {
      final e = ServerException();
      expect(e.message, 'Internal server error');
      expect(e.statusCode, isNull);
    });

    test('positive: is an ApiException', () {
      expect(ServerException(), isA<ApiException>());
    });
  });

  group('UnauthorizedException', () {
    test('positive: forces statusCode 401', () {
      expect(UnauthorizedException('nope').statusCode, 401);
      expect(UnauthorizedException('nope').message, 'nope');
    });

    test('edge: default message', () {
      expect(UnauthorizedException().message, 'Unauthorized accessor');
      expect(UnauthorizedException().statusCode, 401);
    });

    test('positive: is an ApiException', () {
      expect(UnauthorizedException(), isA<ApiException>());
    });
  });

  group('ValidationException', () {
    test('positive: message and status retained', () {
      final e = ValidationException('bad field', 422);
      expect(e.message, 'bad field');
      expect(e.statusCode, 422);
    });

    test('edge: default message and null status', () {
      final e = ValidationException();
      expect(e.message, 'Validation failed');
      expect(e.statusCode, isNull);
    });

    test('positive: is an ApiException', () {
      expect(ValidationException(), isA<ApiException>());
    });
  });

  group('NoInternetException', () {
    test('positive: default reason is disconnected', () {
      final e = NoInternetException();
      expect(e.reason, 'disconnected');
      expect(e.message, 'No internet connection (disconnected)');
    });

    test('edge: custom reason embedded in message', () {
      final e = NoInternetException(reason: 'airplane-mode');
      expect(e.reason, 'airplane-mode');
      expect(e.message, 'No internet connection (airplane-mode)');
    });

    test('positive: is a NetworkException and ApiException', () {
      final e = NoInternetException();
      expect(e, isA<NetworkException>());
      expect(e, isA<ApiException>());
      expect(e.statusCode, isNull);
    });
  });
}
