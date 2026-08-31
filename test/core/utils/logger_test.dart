import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/utils/logger.dart';

void main() {
  group('log', () {
    test('positive: logs a simple message without throwing', () {
      expect(() => log('hello'), returnsNormally);
    });

    test('positive: logs with a custom name', () {
      expect(() => log('tagged', name: 'rewardhub.test'), returnsNormally);
    });

    test('edge: logs with error and stack trace', () {
      expect(
        () => log(
          'failure',
          name: 'rewardhub.auth',
          error: Exception('boom'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('edge: empty message does not throw', () {
      expect(() => log(''), returnsNormally);
    });
  });
}
