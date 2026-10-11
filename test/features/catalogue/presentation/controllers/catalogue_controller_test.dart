import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/features/catalogue/presentation/controllers/catalogue_controller.dart';

import '../../../../helpers/harness.dart';

class MockDio extends Mock implements Dio {}

class MockRemoteConfigService extends GetxService
    with Mock
    implements RemoteConfigService {}

void main() {
  late MockDio mockDio;
  late MockRemoteConfigService mockRemoteConfig;
  late Directory tempDir;

  setUp(() async {
    installGetTestHarness();
    mockDio = MockDio();
    mockRemoteConfig = MockRemoteConfigService();
    tempDir = await Directory.systemTemp.createTemp('catalogue_test_');

    when(() => mockRemoteConfig.catalogueUrl)
        .thenReturn('https://example.com/test_catalogue.pdf');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    await resetGet();
  });

  CatalogueController createController() => CatalogueController(
        dio: mockDio,
        remoteConfigService: mockRemoteConfig,
        getTempDir: () async => tempDir,
      );

  group('CatalogueController', () {
    test('positive: downloads and caches PDF successfully', () async {
      when(
        () => mockDio.download(
          any(),
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        final savePath = invocation.positionalArguments[1] as String;
        final progressCb = invocation.namedArguments[#onReceiveProgress] as void
            Function(int, int)?;
        progressCb?.call(50, 100);
        progressCb?.call(100, 100);

        final file = File(savePath);
        await file.writeAsString('%PDF-1.4 test content');
        return Response<dynamic>(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
        );
      });

      final controller = createController();
      controller.onInit();
      await controller.loadPdf();

      expect(controller.state.value, isA<ViewStateSuccess<String>>());
      expect(controller.downloadProgress.value, 1.0);
    });

    test('positive: uses existing local cache when file is already downloaded',
        () async {
      final controller = createController();
      const testUrl = 'https://example.com/cached.pdf';
      controller.pdfUrl.value = testUrl;

      // Simulate existing cached file matching the hashing scheme
      final safeName =
          base64Url.encode(utf8.encode(testUrl)).replaceAll('=', '');
      final truncatedName =
          safeName.length > 32 ? safeName.substring(0, 32) : safeName;
      final cachedFile = File('${tempDir.path}/catalogue_$truncatedName.pdf');
      await cachedFile.writeAsString('%PDF-1.4 dummy');

      await controller.loadPdf();

      // Should succeed from cache without calling dio.download
      expect(controller.state.value, isA<ViewStateSuccess<String>>());
      verifyNever(
        () => mockDio.download(
          any(),
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          options: any(named: 'options'),
        ),
      );
    });

    test('negative: handles download failure and sets ViewStateError',
        () async {
      when(
        () => mockDio.download(
          any(),
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Connection timeout',
        ),
      );

      final controller = createController();
      await controller.loadPdf();

      expect(controller.state.value, isA<ViewStateError<String>>());
    });

    group('no reload on revisit (UX-21)', () {
      void stubDownload({Future<void>? gate}) {
        when(
          () => mockDio.download(
            any(),
            any(),
            onReceiveProgress: any(named: 'onReceiveProgress'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((invocation) async {
          if (gate != null) await gate;
          final savePath = invocation.positionalArguments[1] as String;
          await File(savePath).writeAsString('%PDF-1.4 test content');
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          );
        });
      }

      CatalogueController controllerWithUrl() =>
          createController()..pdfUrl.value = 'https://example.com/c.pdf';

      void verifyDownloads(int times) => verify(
            () => mockDio.download(
              any(),
              any(),
              onReceiveProgress: any(named: 'onReceiveProgress'),
              options: any(named: 'options'),
            ),
          ).called(times);

      test('after a successful load, loadPdf() keeps state and page', () async {
        stubDownload();
        final controller = controllerWithUrl();
        await controller.loadPdf();
        final loaded = controller.state.value;
        controller.onPdfRender(40);
        controller.onPageChanged(11, 40);

        await controller.loadPdf();
        await controller.loadPdf();
        await controller.loadPdf();

        expect(controller.state.value, same(loaded));
        expect(controller.currentPage.value, 11);
        expect(controller.isPdfReady.value, isTrue);
        verifyDownloads(1);
      });

      test('a second loadPdf() joins the load in flight', () async {
        final gate = Completer<void>();
        stubDownload(gate: gate.future);
        final controller = controllerWithUrl();

        final first = controller.loadPdf();
        final second = controller.loadPdf();
        var secondDone = false;
        unawaited(second.then((_) => secondDone = true));
        await Future<void>.delayed(Duration.zero);
        expect(secondDone, isFalse);

        gate.complete();
        await Future.wait([first, second]);

        expect(controller.state.value, isA<ViewStateSuccess<String>>());
        verifyDownloads(1);
      });

      test('a forced refresh downloads again and returns to page 1', () async {
        stubDownload();
        final controller = controllerWithUrl();
        await controller.loadPdf();
        controller.onPdfRender(40);
        controller.onPageChanged(11, 40);

        await controller.loadPdf(forceRefresh: true);

        expect(controller.currentPage.value, 0);
        expect(controller.totalPages.value, 0);
        expect(controller.state.value, isA<ViewStateSuccess<String>>());
        verifyDownloads(2);
      });

      test('from an error state, loadPdf() loads again', () async {
        final controller = controllerWithUrl();
        controller.onPdfError('Render failed');
        stubDownload();

        await controller.loadPdf();

        expect(controller.state.value, isA<ViewStateSuccess<String>>());
        verifyDownloads(1);
      });

      test('an empty URL shows the plain unavailable message', () async {
        final controller = createController();
        controller.pdfUrl.value = '';

        await controller.loadPdf();

        expect(
          (controller.state.value as ViewStateError<String>).message,
          'Catalogue not available right now. Please try again later.',
        );
      });
    });

    test('positive: page tracking callbacks update observables', () {
      final controller = createController();

      controller.onPdfRender(24);
      expect(controller.totalPages.value, 24);
      expect(controller.isPdfReady.value, isTrue);

      controller.onPageChanged(5, 24);
      expect(controller.currentPage.value, 5);
      expect(controller.totalPages.value, 24);
    });

    test('negative: onPdfError sets error state', () {
      final controller = createController();
      controller.onPdfError('Render failed');

      expect(controller.state.value, isA<ViewStateError<String>>());
    });
  });
}
