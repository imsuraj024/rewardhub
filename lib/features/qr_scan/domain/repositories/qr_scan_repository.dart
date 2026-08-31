import 'package:rewardhub/features/qr_scan/data/models/qr_scan_response_model.dart';

/// Domain contract for submitting scanned QR codes.
abstract interface class QrScanRepository {
  Future<QrScanResponseModel> submitQrScan({
    required String qrData,
    required String token,
  });
}
