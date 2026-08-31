import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/utils/view_state.dart';

void main() {
  group('ViewStateInitial', () {
    test('positive: not loading and no error message', () {
      const s = ViewStateInitial<int>();
      expect(s.isLoading, isFalse);
      expect(s.errorMessage, isNull);
    });
  });

  group('ViewStateLoading', () {
    test('positive: isLoading is true', () {
      const s = ViewStateLoading<int>();
      expect(s.isLoading, isTrue);
    });

    test('edge: loading has no error message', () {
      const ViewState<int> s = ViewStateLoading<int>();
      expect(s.errorMessage, isNull);
    });
  });

  group('ViewStateSuccess', () {
    test('positive: exposes provided data', () {
      const s = ViewStateSuccess<int>(42);
      expect(s.data, 42);
      expect(s.isLoading, isFalse);
      expect(s.errorMessage, isNull);
    });

    test('edge: data defaults to null when omitted', () {
      const s = ViewStateSuccess<int>();
      expect(s.data, isNull);
    });

    test('edge: supports complex/nullable payloads', () {
      const s = ViewStateSuccess<List<String>>(['a', 'b']);
      expect(s.data, ['a', 'b']);
    });
  });

  group('ViewStateError', () {
    test('positive: errorMessage returns the message', () {
      const s = ViewStateError<int>('failed');
      expect(s.errorMessage, 'failed');
      expect(s.isLoading, isFalse);
    });

    test('edge: empty error message preserved', () {
      const s = ViewStateError<int>('');
      expect(s.errorMessage, '');
    });
  });

  group('polymorphism via base type', () {
    test('positive: isLoading only true for loading', () {
      final states = <ViewState<int>>[
        const ViewStateInitial(),
        const ViewStateLoading(),
        const ViewStateSuccess(1),
        const ViewStateError('e'),
      ];
      expect(states.map((s) => s.isLoading).toList(),
          [false, true, false, false]);
    });

    test('positive: errorMessage only set for error', () {
      final states = <ViewState<int>>[
        const ViewStateInitial(),
        const ViewStateLoading(),
        const ViewStateSuccess(1),
        const ViewStateError('e'),
      ];
      expect(states.map((s) => s.errorMessage).toList(),
          [null, null, null, 'e']);
    });
  });
}
