import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rewardhub/core/network/connection_status.dart';
import 'package:rewardhub/core/services/connectivity_service.dart';
import 'package:rewardhub/core/services/i_connectivity_service.dart';

/// A widget that listens to [IConnectivityService.statusStream] and displays
/// a [MaterialBanner] above [child] when the connection is degraded.
///
/// - [ConnectionStatus.disconnected]: non-dismissible red banner
/// - [ConnectionStatus.slow]: dismissible amber banner
/// - [ConnectionStatus.connected]: renders [child] with no banner
class ConnectivityWidget extends StatefulWidget {
  const ConnectivityWidget({
    super.key,
    required this.child,
    this.service,
  });

  final Widget child;

  /// Optional [IConnectivityService] override — useful for testing.
  final IConnectivityService? service;

  @override
  State<ConnectivityWidget> createState() => _ConnectivityWidgetState();
}

class _ConnectivityWidgetState extends State<ConnectivityWidget> {
  ConnectionStatus _status = ConnectionStatus.connected;
  late final StreamSubscription<ConnectionStatus> _subscription;

  @override
  void initState() {
    super.initState();
    final service = widget.service ?? ConnectivityService();
    _subscription = service.statusStream.listen((status) {
      setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showBanner = _status != ConnectionStatus.connected;

    MaterialBanner? banner;
    if (_status == ConnectionStatus.disconnected) {
      banner = MaterialBanner(
        backgroundColor: Colors.red.shade700,
        content: Semantics(
          label: 'No internet connection',
          child: Text(
            'No internet connection',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: const [SizedBox.shrink()],
      );
    } else if (_status == ConnectionStatus.slow) {
      banner = MaterialBanner(
        backgroundColor: Colors.amber.shade700,
        content: Semantics(
          label: 'Slow connection detected',
          child: Text(
            'Slow connection detected',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                setState(() => _status = ConnectionStatus.connected),
            child: const Text(
              'Dismiss',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (showBanner && banner != null) banner,
        Expanded(child: widget.child),
      ],
    );
  }
}
