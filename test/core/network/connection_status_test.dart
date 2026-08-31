import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/network/connection_status.dart';

void main() {
  group('ConnectionStatus', () {
    test('positive: has exactly three values', () {
      expect(ConnectionStatus.values.length, 3);
    });

    test('positive: values are in the expected order', () {
      expect(ConnectionStatus.values, [
        ConnectionStatus.connected,
        ConnectionStatus.slow,
        ConnectionStatus.disconnected,
      ]);
    });

    test('edge: indices match declaration order', () {
      expect(ConnectionStatus.connected.index, 0);
      expect(ConnectionStatus.slow.index, 1);
      expect(ConnectionStatus.disconnected.index, 2);
    });

    test('positive: name lookup by value works', () {
      expect(ConnectionStatus.connected.name, 'connected');
      expect(ConnectionStatus.slow.name, 'slow');
      expect(ConnectionStatus.disconnected.name, 'disconnected');
    });
  });
}
