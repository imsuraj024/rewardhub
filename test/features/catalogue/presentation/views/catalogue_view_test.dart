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
      expect(find.text('Loading catalogue…'), findsOneWidget);
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

      expect(find.text("Couldn't load catalogue"), findsOneWidget);
      expect(find.text('Network connection failed.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      verify(() => mockController.loadPdf(forceRefresh: true)).called(1);
    });

    testWidgets('tapping refresh button in AppBar calls loadPdf',
        (tester) async {
      when(() => mockController.state)
          .thenReturn(const ViewStateLoading<String>().obs);
      Get.put<CatalogueController>(mockController);

      await pumpApp(tester, const CatalogueView());
      await tester.pump();

      expect(find.byTooltip('Reload catalogue'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      verify(() => mockController.loadPdf(forceRefresh: true)).called(1);
    });

    testWidgets('shows "Page x of y" under the title once the PDF is ready',
        (tester) async {
      when(() => mockController.state)
          .thenReturn(const ViewStateLoading<String>().obs);
      when(() => mockController.isPdfReady).thenReturn(true.obs);
      when(() => mockController.totalPages).thenReturn(40.obs);
      when(() => mockController.currentPage).thenReturn(2.obs);
      Get.put<CatalogueController>(mockController);

      await pumpApp(tester, const CatalogueView());
      await tester.pump();

      expect(find.text('Page 3 of 40'), findsOneWidget);
      expect(find.byTooltip('Go to page'), findsOneWidget);
    });
  });

  group('Go to page dialog', () {
    setUp(() {
      when(() => mockController.state)
          .thenReturn(const ViewStateLoading<String>().obs);
      when(() => mockController.isPdfReady).thenReturn(true.obs);
      when(() => mockController.totalPages).thenReturn(40.obs);
      when(() => mockController.currentPage).thenReturn(2.obs);
      when(() => mockController.jumpToPage(any())).thenAnswer((_) async {});
    });

    Future<void> openDialog(WidgetTester tester) async {
      Get.put<CatalogueController>(mockController);
      await pumpApp(tester, const CatalogueView());
      await tester.pump();
      await tester.tap(find.byTooltip('Go to page'));
      await tester.pumpAndSettle();
    }

    testWidgets('an out-of-range page keeps the dialog open with an error',
        (tester) async {
      await openDialog(tester);

      expect(find.text('Go to page'), findsOneWidget);
      expect(find.text('Enter a page from 1 to 40'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(find.text('Enter a number from 1 to 40.'), findsOneWidget);

      // Typing again clears the error.
      await tester.enterText(find.byType(TextField), '41');
      await tester.pump();
      expect(find.text('Enter a number from 1 to 40.'), findsNothing);

      // The keyboard's Go key submits too.
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();
      expect(find.text('Enter a number from 1 to 40.'), findsOneWidget);
      expect(find.text('Go to page'), findsOneWidget);
      verifyNever(() => mockController.jumpToPage(any()));
    });

    testWidgets('an empty value shows the error', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(find.text('Enter a number from 1 to 40.'), findsOneWidget);
    });

    testWidgets('letters cannot be typed', (tester) async {
      await openDialog(tester);

      await tester.enterText(find.byType(TextField), '1a2');
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '12',
      );
    });

    testWidgets('a valid page closes the dialog and jumps once',
        (tester) async {
      await openDialog(tester);

      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a page from 1 to 40'), findsNothing);
      verify(() => mockController.jumpToPage(11)).called(1);
    });
  });

  // The test font's glyphs are full-em squares (about twice Inter's width),
  // so 1.3x here is wider than 2.0x Inter on a device.
  Future<void> pumpSmall(
    WidgetTester tester,
    Widget child, {
    double textScale = 2.0,
  }) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('loading and error states fit 320x568 at 2.0x text',
      (tester) async {
    when(() => mockController.state)
        .thenReturn(const ViewStateLoading<String>().obs);
    Get.put<CatalogueController>(mockController);
    await pumpSmall(tester, const CatalogueView());
    expect(tester.takeException(), isNull);
  });

  testWidgets('error state fits 320x568 at large text', (tester) async {
    when(() => mockController.state).thenReturn(
      const ViewStateError<String>('Check your internet and try again.').obs,
    );
    Get.put<CatalogueController>(mockController);
    await pumpSmall(tester, const CatalogueView(), textScale: 1.3);
    expect(tester.takeException(), isNull);
  });
}
