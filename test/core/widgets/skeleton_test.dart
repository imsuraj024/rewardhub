import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/widgets/skeleton.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('SkeletonBox', () {
    testWidgets('positive: renders with the given height and radius',
        (tester) async {
      await tester.pumpWidget(
        wrap(const SkeletonBox(width: 100, height: 20, radius: 12)),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));

      final size = tester.getSize(find.byType(SkeletonBox));
      expect(size.height, 20);
      expect(size.width, 100);
    });

    testWidgets('edge: null width lets the box expand to its parent',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 300,
            child: SkeletonBox(height: 16),
          ),
        ),
      );

      final size = tester.getSize(find.byType(SkeletonBox));
      expect(size.width, 300);
      expect(size.height, 16);
    });

    testWidgets('edge: uses the default radius of 8 when unspecified',
        (tester) async {
      await tester.pumpWidget(wrap(const SkeletonBox(height: 10)));

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('edge: accepts a zero height without throwing',
        (tester) async {
      await tester.pumpWidget(wrap(const SkeletonBox(height: 0)));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SkeletonBox)).height, 0);
    });
  });

  group('Shimmer', () {
    testWidgets('positive: renders its child inside a ShaderMask',
        (tester) async {
      await tester.pumpWidget(
        wrap(const Shimmer(child: SkeletonBox(width: 50, height: 50))),
      );

      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('edge: animation keeps running across pumps without error',
        (tester) async {
      await tester.pumpWidget(
        wrap(const Shimmer(child: SkeletonBox(width: 50, height: 50))),
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('edge: disposes its controller cleanly', (tester) async {
      await tester.pumpWidget(
        wrap(const Shimmer(child: SkeletonBox(height: 10))),
      );

      await tester.pumpWidget(wrap(const SizedBox()));
      expect(tester.takeException(), isNull);
    });
  });
}
