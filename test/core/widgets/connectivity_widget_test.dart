import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/network/connection_status.dart';
import 'package:rewardhub/core/services/i_connectivity_service.dart';
import 'package:rewardhub/core/widgets/connectivity_widget.dart';

/// A fake connectivity service backed by a controllable stream.
class _FakeConnectivityService implements IConnectivityService {
  final StreamController<ConnectionStatus> _controller =
      StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _current = ConnectionStatus.connected;

  @override
  Stream<ConnectionStatus> get statusStream => _controller.stream;

  @override
  ConnectionStatus get currentStatus => _current;

  void emit(ConnectionStatus status) {
    _current = status;
    _controller.add(status);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

void main() {
  late _FakeConnectivityService service;

  setUp(() => service = _FakeConnectivityService());
  tearDown(() => service.dispose());

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('positive: renders the child while connected', (tester) async {
    await tester.pumpWidget(
      wrap(
        ConnectivityWidget(
          service: service,
          child: const Text('online-content'),
        ),
      ),
    );

    expect(find.text('online-content'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('negative: shows a red banner when disconnected',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        ConnectivityWidget(
          service: service,
          child: const Text('content'),
        ),
      ),
    );

    service.emit(ConnectionStatus.disconnected);
    await tester.pump();

    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('No internet connection'), findsOneWidget);
    // The child stays mounted behind the banner.
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('negative: shows a dismissible amber banner when slow',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        ConnectivityWidget(
          service: service,
          child: const Text('content'),
        ),
      ),
    );

    service.emit(ConnectionStatus.slow);
    await tester.pump();

    expect(find.text('Slow connection detected'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('edge: tapping Dismiss hides the slow banner', (tester) async {
    await tester.pumpWidget(
      wrap(
        ConnectivityWidget(
          service: service,
          child: const Text('content'),
        ),
      ),
    );

    service.emit(ConnectionStatus.slow);
    await tester.pump();
    expect(find.text('Slow connection detected'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pump();

    expect(find.byType(MaterialBanner), findsNothing);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('edge: recovering from disconnected removes the banner',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        ConnectivityWidget(
          service: service,
          child: const Text('content'),
        ),
      ),
    );

    service.emit(ConnectionStatus.disconnected);
    await tester.pump();
    expect(find.byType(MaterialBanner), findsOneWidget);

    service.emit(ConnectionStatus.connected);
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('edge: transitions disconnected -> slow swap banner content',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        ConnectivityWidget(
          service: service,
          child: const Text('content'),
        ),
      ),
    );

    service.emit(ConnectionStatus.disconnected);
    await tester.pump();
    expect(find.text('No internet connection'), findsOneWidget);

    service.emit(ConnectionStatus.slow);
    await tester.pumpAndSettle();
    expect(find.text('No internet connection'), findsNothing);
    expect(find.text('Slow connection detected'), findsOneWidget);
  });

  testWidgets('edge: cancels its subscription on dispose', (tester) async {
    await tester.pumpWidget(
      wrap(
        ConnectivityWidget(
          service: service,
          child: const Text('content'),
        ),
      ),
    );

    // Replace the widget tree so ConnectivityWidget is disposed.
    await tester.pumpWidget(wrap(const Text('replaced')));

    // Emitting after dispose must not throw / call setState on a dead state.
    service.emit(ConnectionStatus.disconnected);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('replaced'), findsOneWidget);
  });
}
