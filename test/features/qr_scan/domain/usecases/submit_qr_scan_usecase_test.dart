import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/qr_scan/data/models/qr_scan_response_model.dart';
import 'package:rewardhub/features/qr_scan/domain/repositories/qr_scan_repository.dart';
import 'package:rewardhub/features/qr_scan/domain/usecases/submit_qr_scan_usecase.dart';

class MockQrScanRepository extends Mock implements QrScanRepository {}

void main() {
  late MockQrScanRepository repository;
  late SubmitQrScanUseCase useCase;

  setUp(() {
    repository = MockQrScanRepository();
    useCase = SubmitQrScanUseCase(repository);
  });

  group('SubmitQrScanUseCase.call', () {
    test('positive: forwards qrData and token, returns result', () async {
      final response =
          QrScanResponseModel(success: true, pointsEarned: 30);
      when(() => repository.submitQrScan(
            qrData: any(named: 'qrData'),
            token: any(named: 'token'),
          )).thenAnswer((_) async => response);

      final result = await useCase(
        const SubmitQrScanParams(qrData: 'QR123', token: 'tok'),
      );

      expect(result, same(response));
      verify(() => repository.submitQrScan(qrData: 'QR123', token: 'tok'))
          .called(1);
      verifyNoMoreInteractions(repository);
    });

    test('negative: propagates business failures', () async {
      when(() => repository.submitQrScan(
            qrData: any(named: 'qrData'),
            token: any(named: 'token'),
          )).thenThrow(ApiException('already scanned'));

      expect(
        () => useCase(const SubmitQrScanParams(qrData: 'QR', token: 't')),
        throwsA(isA<ApiException>()),
      );
    });

    test('edge: empty qrData is still forwarded verbatim', () async {
      when(() => repository.submitQrScan(
            qrData: any(named: 'qrData'),
            token: any(named: 'token'),
          )).thenAnswer((_) async => QrScanResponseModel(success: false));

      await useCase(const SubmitQrScanParams(qrData: '', token: 'tok'));

      verify(() => repository.submitQrScan(qrData: '', token: 'tok')).called(1);
    });
  });
}
