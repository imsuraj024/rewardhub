import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:rewardhub/core/network/connection_status.dart';
import 'package:rewardhub/core/services/i_connectivity_service.dart';
import 'package:rewardhub/core/utils/logger.dart';

/// Singleton service that monitors internet connectivity and connection quality.
///
/// Implements [IConnectivityService] for status stream/getter access and
/// mixes in [WidgetsBindingObserver] to re-probe when the app resumes from
/// background.
class ConnectivityService
    with WidgetsBindingObserver
    implements IConnectivityService {
  // ── Singleton ────────────────────────────────────────────────────────────

  static ConnectivityService? _instance;

  /// Returns the existing singleton or creates a new one with the given params.
  factory ConnectivityService({
    String speedProbeUrl = 'https://www.google.com',
    int slowThresholdMs = 2000,
    Duration pollingInterval = const Duration(seconds: 10),
  }) {
    _instance ??= ConnectivityService._internal(
      speedProbeUrl: speedProbeUrl,
      slowThresholdMs: slowThresholdMs,
      pollingInterval: pollingInterval,
    );
    return _instance!;
  }

  ConnectivityService._internal({
    required String speedProbeUrl,
    required int slowThresholdMs,
    required Duration pollingInterval,
  })  : _speedProbeUrl = speedProbeUrl,
        _slowThresholdMs = slowThresholdMs {
    // Dedicated Dio instance for HEAD probes only.
    _probeDio = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: _slowThresholdMs),
        receiveTimeout: Duration(milliseconds: _slowThresholdMs),
      ),
    );

    // Register lifecycle observer.
    WidgetsBinding.instance.addObserver(this);

    // Subscribe to platform network-change events.
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((_) => _probe());

    // Start periodic polling.
    _pollingTimer = Timer.periodic(pollingInterval, (_) => _probe());

    // Run an initial probe immediately.
    _probe();
  }

  // ── Configuration ────────────────────────────────────────────────────────

  final String _speedProbeUrl;
  final int _slowThresholdMs;

  // ── State ────────────────────────────────────────────────────────────────

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  // Start optimistic: until the first probe completes we assume connectivity,
  // so requests fired right after launch (e.g. on a restored session) aren't
  // rejected during the brief unknown window. The probe flips this to
  // `disconnected` if the device is actually offline.
  ConnectionStatus _currentStatus = ConnectionStatus.connected;

  bool _disposed = false;

  // ── Infrastructure ───────────────────────────────────────────────────────

  late final Dio _probeDio;
  late final Timer _pollingTimer;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // ── IConnectivityService ─────────────────────────────────────────────────

  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  // ── Probing ──────────────────────────────────────────────────────────────

  Future<void> _probe() async {
    if (_disposed) return;

    ConnectionStatus newStatus;

    try {
      final stopwatch = Stopwatch()..start();
      await _probeDio.head(_speedProbeUrl);
      stopwatch.stop();

      newStatus = stopwatch.elapsedMilliseconds > _slowThresholdMs
          ? ConnectionStatus.slow
          : ConnectionStatus.connected;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        newStatus = ConnectionStatus.slow;
      } else {
        log(
          'Connectivity probe failed',
          name: 'ConnectivityService',
          error: e,
          stackTrace: e.stackTrace,
        );
        newStatus = ConnectionStatus.disconnected;
      }
    } catch (e, st) {
      log(
        'Connectivity probe encountered unexpected error',
        name: 'ConnectivityService',
        error: e,
        stackTrace: st,
      );
      newStatus = ConnectionStatus.disconnected;
    }

    if (_disposed) return;

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
      log(
        'Connection status changed → ${newStatus.name}',
        name: 'ConnectivityService',
      );
      debugPrint('[ConnectivityService] status → ${newStatus.name}');
    }
  }

  // ── WidgetsBindingObserver ───────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _probe();
    }
  }

  // ── Disposal ─────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _pollingTimer.cancel();
    await _connectivitySubscription.cancel();
    await _statusController.close();
    WidgetsBinding.instance.removeObserver(this);
    _probeDio.close();

    // Allow the singleton to be recreated after disposal.
    _instance = null;
  }
}
