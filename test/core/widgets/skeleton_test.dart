import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/theme/app_colors.dart';
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

    testWidgets('positive: onDark uses a translucent white block',
        (tester) async {
      await tester.pumpWidget(wrap(const SkeletonBox(height: 40, onDark: true)));

      final container = tester.widget<Container>(find.byType(Container));
      final color = (container.decoration as BoxDecoration).color!;
      expect(color.r, 1.0);
      expect(color.g, 1.0);
      expect(color.b, 1.0);
      expect((color.a * 255).round(), closeTo(0x3D, 1));
    });

    testWidgets('edge: light blocks keep surfaceContainerHigh', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonBox(height: 40)));

      final container = tester.widget<Container>(find.byType(Container));
      expect(
        (container.decoration as BoxDecoration).color,
        AppColors.surfaceContainerHigh,
      );
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

    testWidgets('positive: light shimmer paints over its child',
        (tester) async {
      await tester.pumpWidget(
        wrap(const Shimmer(child: SkeletonBox(width: 50, height: 50))),
      );

      final mask = tester.widget<ShaderMask>(find.byType(ShaderMask));
      expect(mask.blendMode, BlendMode.srcATop);
    });

    testWidgets('positive: onDark shimmer masks alpha with dstIn',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const Shimmer(
            onDark: true,
            child: SkeletonBox(width: 50, height: 50, onDark: true),
          ),
        ),
      );

      final mask = tester.widget<ShaderMask>(find.byType(ShaderMask));
      expect(mask.blendMode, BlendMode.dstIn);
    });

    testWidgets('edge: reduced motion shows the child still, with no ticker',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: Shimmer(child: SkeletonBox(width: 50, height: 50)),
            ),
          ),
        ),
      );

      expect(find.byType(ShaderMask), findsNothing);
      expect(find.byType(SkeletonBox), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('edge: shimmer is excluded from semantics', (tester) async {
      await tester.pumpWidget(
        wrap(const Shimmer(child: SkeletonBox(width: 50, height: 50))),
      );

      expect(
        find.ancestor(
          of: find.byType(SkeletonBox),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
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
