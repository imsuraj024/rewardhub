import 'package:rewardhub/core/network/connection_status.dart';

abstract interface class IConnectivityService {
  Stream<ConnectionStatus> get statusStream;
  ConnectionStatus get currentStatus;
  Future<void> dispose();
}
