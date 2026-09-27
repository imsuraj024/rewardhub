import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rewardhub/core/network/connection_status.dart';
import 'package:rewardhub/core/services/i_connectivity_service.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
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

const offline = "You're offline. Your points may not be up to date.";
const slow = 'Slow internet. Things may take longer to load.';

/// Counts its own `initState` calls so a test can tell whether its State
/// survived a rebuild of the tree above it.
class _StatefulProbe extends StatefulWidget {
  const _StatefulProbe({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_StatefulProbe> createState() => _StatefulProbeState();
}

class _StatefulProbeState extends State<_StatefulProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Text('probe');
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

  testWidgets('negative: shows an error-tinted banner when disconnected',
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
    expect(find.text(offline), findsOneWidget);
    // The child stays mounted behind the banner.
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('negative: shows a dismissible warning banner when slow',
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

    expect(find.text(slow), findsOneWidget);
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
    expect(find.text(slow), findsOneWidget);

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
    expect(find.text(offline), findsOneWidget);

    service.emit(ConnectionStatus.slow);
    await tester.pumpAndSettle();
    expect(find.text(offline), findsNothing);
    expect(find.text(slow), findsOneWidget);
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

  testWidgets('positive: an offline start shows the banner on the first frame',
      (tester) async {
    service.emit(ConnectionStatus.disconnected);

    await tester.pumpWidget(
      wrap(
        ConnectivityWidget(
          service: service,
          child: const Text('content'),
        ),
      ),
    );

    expect(find.text(offline), findsOneWidget);
  });

  testWidgets('positive: banners use the tokenised colour pairs',
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
    await tester.pumpAndSettle();
    var banner = tester.widget<MaterialBanner>(find.byType(MaterialBanner));
    expect(banner.backgroundColor, AppColors.errorContainer);
    expect(
      tester.widget<Text>(find.text(offline)).style?.color,
      AppColors.onErrorContainer,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.wifi_off_rounded)).color,
      AppColors.error,
    );

    service.emit(ConnectionStatus.slow);
    await tester.pumpAndSettle();
    banner = tester.widget<MaterialBanner>(find.byType(MaterialBanner));
    expect(banner.backgroundColor, AppColors.warningContainer);
    expect(
      tester.widget<Text>(find.text(slow)).style?.color,
      AppColors.onWarningContainer,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.network_check_rounded)).color,
      AppColors.warning,
    );
  });

  testWidgets('positive: the banner is announced as a live region',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        ConnectivityWidget(
          service: service,
          child: const Text('content'),
        ),
      ),
    );

    service.emit(ConnectionStatus.disconnected);
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text(offline)),
      isSemantics(isLiveRegion: true, label: offline),
    );
    handle.dispose();
  });

  testWidgets('edge: the child keeps its State as the banner comes and goes',
      (tester) async {
    var inits = 0;
    await tester.pumpWidget(
      wrap(
        ConnectivityWidget(
          service: service,
          child: _StatefulProbe(onInit: () => inits++),
        ),
      ),
    );
    expect(inits, 1);

    service.emit(ConnectionStatus.disconnected);
    await tester.pumpAndSettle();
    expect(find.text(offline), findsOneWidget);

    service.emit(ConnectionStatus.connected);
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);

    expect(inits, 1);
    expect(find.text('probe'), findsOneWidget);
  });

  testWidgets('edge: the page below the banner loses its top inset',
      (tester) async {
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.reset);
    double? childTopPadding;

    await tester.pumpWidget(
      MaterialApp(
        home: ConnectivityWidget(
          service: service,
          child: Builder(
            builder: (context) {
              childTopPadding = MediaQuery.paddingOf(context).top;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    expect(childTopPadding, greaterThan(0));

    service.emit(ConnectionStatus.disconnected);
    await tester.pumpAndSettle();
    expect(childTopPadding, 0);
  });

  testWidgets('edge: mounted like main.dart, above the Navigator, it shows '
      'over routes and sheets', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => ConnectivityWidget(
          service: service,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: Text('page')),
      ),
    );

    service.emit(ConnectionStatus.disconnected);
    await tester.pumpAndSettle();
    expect(find.text(offline), findsOneWidget);
    expect(find.text('page'), findsOneWidget);

    Get.bottomSheet<void>(
      const Material(child: SizedBox(height: 120, child: Text('sheet'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);
    expect(find.text(offline), findsOneWidget);

    service.emit(ConnectionStatus.connected);
    await tester.pumpAndSettle();
    expect(find.text(offline), findsNothing);
    expect(find.text('sheet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
