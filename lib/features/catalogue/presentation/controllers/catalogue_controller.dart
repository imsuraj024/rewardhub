import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rewardhub/core/services/remote_config_service.dart';
import 'package:rewardhub/core/utils/logger.dart';
import 'package:rewardhub/core/utils/view_state.dart';

/// Manages downloading, caching, and navigation of PDF catalogues.
class CatalogueController extends GetxController {
  CatalogueController({
    Dio? dio,
    RemoteConfigService? remoteConfigService,
    Future<Directory> Function()? getTempDir,
  })  : _dio = dio ?? Dio(),
        _remoteConfig = remoteConfigService,
        _getTempDir = getTempDir ?? getTemporaryDirectory;

  final Dio _dio;
  final RemoteConfigService? _remoteConfig;
  final Future<Directory> Function() _getTempDir;

  /// Current state of the PDF download/cache operation.
  final Rx<ViewState<String>> state =
      Rx<ViewState<String>>(const ViewStateInitial<String>());

  /// Download progress between 0.0 and 1.0.
  final RxDouble downloadProgress = 0.0.obs;

  /// Current active page index (0-indexed).
  final RxInt currentPage = 0.obs;

  /// Total page count of the loaded PDF.
  final RxInt totalPages = 0.obs;

  /// Whether the PDF viewer engine is fully initialized and ready.
  final RxBool isPdfReady = false.obs;

  /// Title of the catalogue document being viewed.
  final RxString documentTitle = 'Kitox Hardware Catalogue'.obs;

  /// Target remote URL of the PDF document.
  final RxString pdfUrl = ''.obs;

  PDFViewController? _pdfViewController;

  @override
  void onInit() {
    super.onInit();
    _initParams();
    loadPdf();
  }

  void _initParams() {
    final args = Get.arguments;
    if (args is Map) {
      if (args['title'] is String && (args['title'] as String).isNotEmpty) {
        documentTitle.value = args['title'] as String;
      }
      if (args['url'] is String && (args['url'] as String).isNotEmpty) {
        pdfUrl.value = args['url'] as String;
      }
    }

    if (pdfUrl.value.isEmpty) {
      final config = _remoteConfig ??
          (Get.isRegistered<RemoteConfigService>()
              ? Get.find<RemoteConfigService>()
              : null);
      pdfUrl.value = config?.catalogueUrl ??
          'https://raw.githubusercontent.com/mozilla/pdf.js/master/web/compressed.tracemonkey-pldi-09.pdf';
    }
  }

  /// Downloads and caches the PDF file locally, tracking progress.
  Future<void> loadPdf({bool forceRefresh = false}) async {
    final url = pdfUrl.value;
    if (url.isEmpty) {
      state.value = const ViewStateError('Catalogue URL is not available.');
      return;
    }

    state.value = const ViewStateLoading();
    downloadProgress.value = 0.0;
    isPdfReady.value = false;

    try {
      final tempDir = await _getTempDir();
      // Create safe filename from URL
      final safeName = base64Url.encode(utf8.encode(url)).replaceAll('=', '');
      final truncatedName = safeName.length > 32 ? safeName.substring(0, 32) : safeName;
      final filePath = '${tempDir.path}/catalogue_$truncatedName.pdf';
      final file = File(filePath);

      // Return cached file if available and refresh not forced
      if (!forceRefresh && await file.exists() && await file.length() > 0) {
        log('Serving PDF from cache: $filePath', name: 'rewardhub.catalogue');
        downloadProgress.value = 1.0;
        state.value = ViewStateSuccess(filePath);
        return;
      }

      log('Downloading PDF from: $url', name: 'rewardhub.catalogue');
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress.value = (received / total).clamp(0.0, 1.0);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      final downloadedFile = File(filePath);
      if (await downloadedFile.exists() && await downloadedFile.length() > 0) {
        downloadProgress.value = 1.0;
        state.value = ViewStateSuccess(filePath);
      } else {
        state.value = const ViewStateError(
          'Failed to save catalogue file. Please try again.',
        );
      }
    } catch (e, stack) {
      log(
        'Error downloading PDF catalogue: $e',
        name: 'rewardhub.catalogue',
        error: e,
        stackTrace: stack,
      );
      state.value = const ViewStateError(
        'Unable to load catalogue. Please check your internet connection and try again.',
      );
    }
  }

  /// Callback when PDF view is created.
  void onPdfViewCreated(PDFViewController controller) {
    _pdfViewController = controller;
  }

  /// Callback when PDF pages are rendered.
  void onPdfRender(int? pages) {
    totalPages.value = pages ?? 0;
    isPdfReady.value = true;
  }

  /// Callback when page changes.
  void onPageChanged(int? page, int? total) {
    if (page != null) {
      currentPage.value = page;
    }
    if (total != null) {
      totalPages.value = total;
    }
  }

  /// Callback on PDF rendering error.
  void onPdfError(dynamic error) {
    log('PDF View Error: $error', name: 'rewardhub.catalogue');
    state.value = const ViewStateError(
      'Failed to render PDF document. Please try re-downloading.',
    );
  }

  /// Jumps to specific 0-indexed page number.
  Future<void> jumpToPage(int page) async {
    if (_pdfViewController == null || totalPages.value <= 0) return;
    final target = page.clamp(0, totalPages.value - 1);
    await _pdfViewController?.setPage(target);
    currentPage.value = target;
  }

  /// Navigates to next page.
  Future<void> nextPage() async {
    if (currentPage.value < totalPages.value - 1) {
      await jumpToPage(currentPage.value + 1);
    }
  }

  /// Navigates to previous page.
  Future<void> previousPage() async {
    if (currentPage.value > 0) {
      await jumpToPage(currentPage.value - 1);
    }
  }
}
