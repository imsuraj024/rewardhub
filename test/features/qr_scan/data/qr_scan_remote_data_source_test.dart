import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/network/api_client.dart';
import 'package:rewardhub/core/network/api_endpoints.dart';
import 'package:rewardhub/core/network/api_exception.dart';
import 'package:rewardhub/features/qr_scan/data/datasources/qr_scan_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late QrScanRemoteDataSourceImpl dataSource;

  setUp(() {
    api = MockApiClient();
    dataSource = QrScanRemoteDataSourceImpl(apiClient: api);
  });

  group('submitQrScan', () {
    test('positive: maps a successful response to the model', () async {
      when(() => api.post(ApiEndpoints.qrScan, data: any(named: 'data')))
          .thenAnswer((_) async =>
              {'Success': true, 'PointsEarned': 25, 'Message': 'awarded'});

      final result = await dataSource.submitQrScan(qrData: 'QR', token: 't');

      expect(result.success, isTrue);
      expect(result.pointsEarned, 25);
      expect(result.message, 'awarded');
    });

    test('positive: sends QrData and token in the request body', () async {
      Map<String, dynamic>? sent;
      when(() => api.post(ApiEndpoints.qrScan, data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as Map<String, dynamic>;
        return {'Success': true};
      });

      await dataSource.submitQrScan(qrData: 'QR123', token: 'tok');

      expect(sent!['QrData'], 'QR123');
      expect(sent!['token'], 'tok');
    });

    test('negative: business failure throws ApiException', () async {
      when(() => api.post(ApiEndpoints.qrScan, data: any(named: 'data')))
          .thenAnswer(
              (_) async => {'Success': false, 'Message': 'already scanned'});

      expect(
        () => dataSource.submitQrScan(qrData: 'QR', token: 't'),
        throwsA(isA<ApiException>()),
      );
    });

    test('negative: propagates transport errors', () async {
      when(() => api.post(ApiEndpoints.qrScan, data: any(named: 'data')))
          .thenThrow(NetworkException('offline'));

      expect(
        () => dataSource.submitQrScan(qrData: 'QR', token: 't'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('edge: empty JSON defaults success=false and throws', () async {
      when(() => api.post(ApiEndpoints.qrScan, data: any(named: 'data')))
          .thenAnswer((_) async => <String, dynamic>{});

      expect(
        () => dataSource.submitQrScan(qrData: 'QR', token: 't'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
