import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/core/network/error_messages.dart';
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
      expect(msg, ErrorMessages.offline);
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

    test('negative: a generic Exception never leaks its raw text', () {
      expect(resolveErrorMessage(Exception('boom')), ErrorMessages.generic);
    });

    test('edge: an exception without the prefix gets the generic message', () {
      expect(resolveErrorMessage(_NoPrefixError()), ErrorMessages.generic);
    });

    test('edge: FormatException gets the generic message', () {
      expect(
        resolveErrorMessage(const FormatException('bad')),
        ErrorMessages.generic,
      );
    });

    test('edge: empty generic exception gets the generic message', () {
      expect(resolveErrorMessage(Exception('')), ErrorMessages.generic);
    });

    test('edge: an ApiException with a blank message gets the generic one', () {
      expect(resolveErrorMessage(ApiException('  ')), ErrorMessages.generic);
    });

    test('negative: no fallback leaks internal wording', () {
      for (final msg in [
        resolveErrorMessage(Exception('Exception: x')),
        resolveErrorMessage(NoInternetException()),
        resolveErrorMessage(UnauthorizedException()),
      ]) {
        expect(msg, isNot(contains('Exception:')));
        expect(msg, isNot(contains('accessor')));
        expect(msg, isNot(contains('Unexpected error')));
      }
    });
  });
}
