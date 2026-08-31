import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/network/api_endpoints.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/qr_scan/data/models/qr_scan_response_model.dart';

/// Submits scanned QR payloads to the rewards backend.
abstract interface class QrScanRemoteDataSource {
  Future<QrScanResponseModel> submitQrScan({
    required String qrData,
    required String token,
  });
}

class QrScanRemoteDataSourceImpl implements QrScanRemoteDataSource {
  QrScanRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<QrScanResponseModel> submitQrScan({
    required String qrData,
    required String token,
  }) async {
    final data = await _apiClient.post(
      ApiEndpoints.qrScan,
      data: {'QrData': qrData, 'token': token},
    );
    final response = QrScanResponseModel.fromJson(data as Map<String, dynamic>);
    if (!response.success) {
      throw ApiException(response.message ?? 'QR scan failed');
    }
    return response;
  }
}
