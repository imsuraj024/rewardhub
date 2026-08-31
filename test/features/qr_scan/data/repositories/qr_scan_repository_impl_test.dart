import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/qr_scan/data/datasources/qr_scan_remote_data_source.dart';
import 'package:rewardhub/features/qr_scan/data/models/qr_scan_response_model.dart';
import 'package:rewardhub/features/qr_scan/data/repositories/qr_scan_repository_impl.dart';

class MockQrScanRemoteDataSource extends Mock
    implements QrScanRemoteDataSource {}

void main() {
  late MockQrScanRemoteDataSource remote;
  late QrScanRepositoryImpl repository;

  setUp(() {
    remote = MockQrScanRemoteDataSource();
    repository = QrScanRepositoryImpl(remoteDataSource: remote);
  });

  group('submitQrScan', () {
    test('positive: forwards qrData and token, returns result', () async {
      final response = QrScanResponseModel(success: true, pointsEarned: 20);
      when(() => remote.submitQrScan(
            qrData: any(named: 'qrData'),
            token: any(named: 'token'),
          )).thenAnswer((_) async => response);

      final result = await repository.submitQrScan(qrData: 'QR', token: 't');

      expect(result, same(response));
      verify(() => remote.submitQrScan(qrData: 'QR', token: 't')).called(1);
      verifyNoMoreInteractions(remote);
    });

    test('negative: propagates remote errors', () async {
      when(() => remote.submitQrScan(
            qrData: any(named: 'qrData'),
            token: any(named: 'token'),
          )).thenThrow(ApiException('failed'));

      expect(
        () => repository.submitQrScan(qrData: 'QR', token: 't'),
        throwsA(isA<ApiException>()),
      );
    });

    test('edge: empty qrData is forwarded verbatim', () async {
      when(() => remote.submitQrScan(
            qrData: any(named: 'qrData'),
            token: any(named: 'token'),
          )).thenAnswer((_) async => QrScanResponseModel(success: false));

      await repository.submitQrScan(qrData: '', token: 't');

      verify(() => remote.submitQrScan(qrData: '', token: 't')).called(1);
    });
  });
}
