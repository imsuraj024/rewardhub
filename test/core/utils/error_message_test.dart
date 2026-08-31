import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/core/utils/error_message.dart';

/// Exception whose toString does NOT start with the "Exception: " prefix.
class _NoPrefixError implements Exception {
  @override
  String toString() => 'plain failure';
}

void main() {
  group('resolveErrorMessage', () {
    test('positive: NoInternetException always uses friendly copy', () {
      final msg = resolveErrorMessage(NoInternetException(reason: 'airplane'));
      expect(
        msg,
        'No internet connection. Please check your connection and try again.',
      );
      // The internal reason code must not leak to the user.
      expect(msg, isNot(contains('airplane')));
    });

    test('positive: other ApiException uses its own message', () {
      expect(resolveErrorMessage(ApiException('server down')), 'server down');
    });

    test('positive: ApiException subclass message passes through', () {
      expect(
        resolveErrorMessage(ValidationException('bad field', 422)),
        'bad field',
      );
      expect(
        resolveErrorMessage(NetworkException('timeout')),
        'timeout',
      );
    });

    test('negative: generic Exception strips the "Exception: " prefix', () {
      expect(resolveErrorMessage(Exception('boom')), 'boom');
    });

    test('edge: exception without the prefix is returned verbatim', () {
      expect(resolveErrorMessage(_NoPrefixError()), 'plain failure');
    });

    test('edge: FormatException keeps its own type prefix', () {
      // Its toString is "FormatException: bad" which does NOT begin with
      // "Exception: ", so nothing is stripped.
      expect(
        resolveErrorMessage(const FormatException('bad')),
        'FormatException: bad',
      );
    });

    test('edge: empty generic exception yields empty remainder', () {
      expect(resolveErrorMessage(Exception('')), '');
    });
  });
}
