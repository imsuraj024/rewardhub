import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardhub/core/utils/view_state.dart';
import 'package:rewardhub/features/catalogue/presentation/controllers/catalogue_controller.dart';
import 'package:rewardhub/features/catalogue/presentation/views/catalogue_view.dart';

import '../../../../helpers/harness.dart';

class MockCatalogueController extends GetxController
    with Mock
    implements CatalogueController {}

void main() {
  late MockCatalogueController mockController;

  setUp(() {
    installGetTestHarness();
    mockController = MockCatalogueController();

    when(() => mockController.documentTitle)
        .thenReturn('Kitox Hardware Catalogue'.obs);
    when(() => mockController.isPdfReady).thenReturn(false.obs);
    when(() => mockController.totalPages).thenReturn(0.obs);
    when(() => mockController.currentPage).thenReturn(0.obs);
    when(() => mockController.downloadProgress).thenReturn(0.45.obs);
    when(() => mockController.loadPdf(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async {});
  });

  tearDown(resetGet);

  group('CatalogueView', () {
    testWidgets('renders downloading state with progress indicator and title',
        (tester) async {
      when(() => mockController.state)
          .thenReturn(const ViewStateLoading<String>().obs);
      Get.put<CatalogueController>(mockController);

      await pumpApp(tester, const CatalogueView());
      await tester.pump();

      expect(find.text('Kitox Hardware Catalogue'), findsOneWidget);
      expect(find.text('Loading Catalogue...'), findsOneWidget);
      expect(find.text('Downloading 45%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with retry action', (tester) async {
      when(() => mockController.state).thenReturn(
        const ViewStateError<String>('Network connection failed.').obs,
      );
      Get.put<CatalogueController>(mockController);

      await pumpApp(tester, const CatalogueView());
      await tester.pump();

      expect(find.text('Unable to Load Catalogue'), findsOneWidget);
      expect(find.text('Network connection failed.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      verify(() => mockController.loadPdf(forceRefresh: true)).called(1);
    });

    testWidgets('tapping refresh button in AppBar calls loadPdf', (tester) async {
      when(() => mockController.state)
          .thenReturn(const ViewStateLoading<String>().obs);
      Get.put<CatalogueController>(mockController);

      await pumpApp(tester, const CatalogueView());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      verify(() => mockController.loadPdf(forceRefresh: true)).called(1);
    });
  });
}
