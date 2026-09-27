import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
import 'package:rewardhub/core/theme/app_radius.dart';
import 'package:rewardhub/core/widgets/app_bottom_sheet.dart';
import 'package:rewardhub/core/widgets/app_button.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const screen = Size(400, 800);

  void usePhone(WidgetTester tester, {double bottomInset = 0}) {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = FakeViewPadding(bottom: bottomInset);
    tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
    addTearDown(tester.view.reset);
  }

  /// Pumps a page with a button that opens the sheet from [open].
  Future<void> pumpHost(
    WidgetTester tester,
    void Function(BuildContext context) open,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => open(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('positive: white sheet, 28 dp top radius and a 40x4 handle',
      (tester) async {
    usePhone(tester);
    await pumpHost(
      tester,
      (context) => AppBottomSheet.show<void>(
        context: context,
        builder: (_) => const AppBottomSheet(title: 'Add photo'),
      ),
    );

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, AppColors.surfaceContainerLowest);
    expect(
      sheet.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    );
    final handle = find.descendant(
      of: find.byType(AppBottomSheet),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints == BoxConstraints.tight(const Size(40, 4)),
      ),
    );
    expect(handle, findsOneWidget);
    expect(find.text('Add photo'), findsOneWidget);
  });

  testWidgets('edge: the last action clears a 34 dp home indicator',
      (tester) async {
    usePhone(tester, bottomInset: 34);
    await pumpHost(
      tester,
      (context) => AppBottomSheet.confirm(
        context: context,
        title: 'Log out?',
        confirmLabel: 'Log out',
      ),
    );

    final cancelBottom = tester.getBottomLeft(find.text('Cancel')).dy;
    final buttonBottom = tester
        .getBottomLeft(
          find.ancestor(
            of: find.text('Cancel'),
            matching: find.byType(AppButton),
          ),
        )
        .dy;
    expect(cancelBottom, lessThan(buttonBottom));
    expect(screen.height - buttonBottom, greaterThanOrEqualTo(34 + 24));
  });

  testWidgets('edge: a tall body scrolls, capped at 0.9x, actions visible',
      (tester) async {
    usePhone(tester);
    await pumpHost(
      tester,
      (context) => AppBottomSheet.show<void>(
        context: context,
        builder: (_) => AppBottomSheet(
          title: 'Long',
          actions: [AppButton(label: 'Done', onPressed: () {})],
          child: const SizedBox(height: 2000, child: Text('tall body')),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final sheetHeight = tester.getSize(find.byType(BottomSheet)).height;
    expect(sheetHeight, lessThanOrEqualTo(screen.height * 0.9));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final doneBottom = tester.getBottomLeft(find.text('Done')).dy;
    expect(doneBottom, lessThanOrEqualTo(screen.height));
  });

  testWidgets('edge: a text field in the body stays above the keyboard',
      (tester) async {
    usePhone(tester);
    await pumpHost(
      tester,
      (context) => AppBottomSheet.show<void>(
        context: context,
        builder: (_) => const AppBottomSheet(
          title: 'Go to page',
          child: TextField(),
        ),
      ),
    );

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    final fieldBottom = tester.getBottomLeft(find.byType(TextField)).dy;
    expect(fieldBottom, lessThanOrEqualTo(screen.height - 300));
  });

  testWidgets('negative: canDismiss false ignores back and scrim taps',
      (tester) async {
    usePhone(tester);
    await pumpHost(
      tester,
      (context) => AppBottomSheet.show<void>(
        context: context,
        enableDrag: false,
        builder: (_) => const AppBottomSheet(
          title: 'Uploading',
          canDismiss: false,
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Uploading'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Uploading'), findsOneWidget);
  });

  group('confirm', () {
    Future<bool?> openConfirm(WidgetTester tester) async {
      bool? result;
      await pumpHost(tester, (context) async {
        result = await AppBottomSheet.confirm(
          context: context,
          title: 'Delete account?',
          message: 'This cannot be undone.',
          confirmLabel: 'Delete',
          icon: Icons.delete_outline_rounded,
          destructive: true,
        );
      });
      return result;
    }

    testWidgets('positive: resolves true on the confirm tap', (tester) async {
      usePhone(tester);
      bool? result;
      await pumpHost(tester, (context) async {
        result = await AppBottomSheet.confirm(
          context: context,
          title: 'Delete account?',
          confirmLabel: 'Delete',
          destructive: true,
        );
      });

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('negative: resolves false on Cancel', (tester) async {
      usePhone(tester);
      bool? result;
      await pumpHost(tester, (context) async {
        result = await AppBottomSheet.confirm(
          context: context,
          title: 'Delete account?',
          confirmLabel: 'Delete',
        );
      });

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('edge: resolves false on back and on a scrim tap',
        (tester) async {
      usePhone(tester);
      bool? result;
      Future<void> open(BuildContext context) async {
        result = await AppBottomSheet.confirm(
          context: context,
          title: 'Delete account?',
          confirmLabel: 'Delete',
        );
      }

      await pumpHost(tester, open);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(result, isFalse);

      result = null;
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('positive: destructive confirm uses the destructive variant',
        (tester) async {
      usePhone(tester);
      await openConfirm(tester);

      final confirm = tester.widget<AppButton>(
        find.ancestor(
          of: find.text('Delete'),
          matching: find.byType(AppButton),
        ),
      );
      expect(confirm.variant, AppButtonVariant.destructive);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });

  testWidgets('edge: the list sheet builds rows lazily', (tester) async {
    usePhone(tester);
    var built = 0;
    await pumpHost(
      tester,
      (context) => AppBottomSheet.show<void>(
        context: context,
        builder: (_) => AppBottomSheet.list(
          title: 'All transactions',
          itemCount: 200,
          itemBuilder: (_, index) {
            built++;
            return SizedBox(height: 56, child: Text('Row $index'));
          },
        ),
      ),
    );

    expect(find.text('All transactions'), findsOneWidget);
    expect(find.text('Row 0'), findsOneWidget);
    expect(built, lessThan(200));
  });
}
