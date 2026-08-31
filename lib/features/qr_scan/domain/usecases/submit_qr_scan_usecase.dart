import 'package:rewardhub/core/usecase/usecase.dart';
import 'package:rewardhub/features/qr_scan/data/models/qr_scan_response_model.dart';
import 'package:rewardhub/features/qr_scan/domain/repositories/qr_scan_repository.dart';

/// Input for [SubmitQrScanUseCase].
class SubmitQrScanParams {
  const SubmitQrScanParams({required this.qrData, required this.token});

  final String qrData;
  final String token;
}

/// Submits a scanned QR payload and returns the rewards outcome.
class SubmitQrScanUseCase
    implements UseCase<QrScanResponseModel, SubmitQrScanParams> {
  const SubmitQrScanUseCase(this._repository);

  final QrScanRepository _repository;

  @override
  Future<QrScanResponseModel> call(SubmitQrScanParams params) {
    return _repository.submitQrScan(qrData: params.qrData, token: params.token);
  }
}
