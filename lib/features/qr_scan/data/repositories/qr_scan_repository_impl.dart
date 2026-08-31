import 'package:rewardhub/features/qr_scan/data/datasources/qr_scan_remote_data_source.dart';
import 'package:rewardhub/features/qr_scan/data/models/qr_scan_response_model.dart';
import 'package:rewardhub/features/qr_scan/domain/repositories/qr_scan_repository.dart';

class QrScanRepositoryImpl implements QrScanRepository {
  QrScanRepositoryImpl({required QrScanRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final QrScanRemoteDataSource _remote;

  @override
  Future<QrScanResponseModel> submitQrScan({
    required String qrData,
    required String token,
  }) =>
      _remote.submitQrScan(qrData: qrData, token: token);
}
