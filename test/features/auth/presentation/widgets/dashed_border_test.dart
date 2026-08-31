import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/auth/presentation/widgets/dashed_border.dart';

void main() {
  // Paints the given painter into a throwaway canvas.
  void paint(DashedRRectPainter painter, Size size) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, size);
    recorder.endRecording().dispose();
  }

  group('paint', () {
    test('positive: paints a dashed border without throwing', () {
      expect(
        () => paint(DashedRRectPainter(), const Size(200, 120)),
        returnsNormally,
      );
    });

    test('edge: paints on a zero-size canvas without throwing', () {
      expect(
        () => paint(DashedRRectPainter(), Size.zero),
        returnsNormally,
      );
    });

    test('edge: handles a gap larger than the perimeter', () {
      expect(
        () => paint(
          DashedRRectPainter(dashLength: 1, gapLength: 10000),
          const Size(50, 50),
        ),
        returnsNormally,
      );
    });

    test('edge: handles custom color, radius and stroke width', () {
      expect(
        () => paint(
          DashedRRectPainter(
            color: const Color(0xFF00FF00),
            radius: 4,
            strokeWidth: 3,
            dashLength: 2,
            gapLength: 2,
          ),
          const Size(80, 80),
        ),
        returnsNormally,
      );
    });
  });

  group('shouldRepaint', () {
    test('positive: repaints when the color differs', () {
      final a = DashedRRectPainter(color: const Color(0xFF000000));
      final b = DashedRRectPainter(color: const Color(0xFFFFFFFF));
      expect(b.shouldRepaint(a), isTrue);
    });

    test('positive: repaints when radius / stroke / dash / gap differ', () {
      final base = DashedRRectPainter();
      expect(DashedRRectPainter(radius: 99).shouldRepaint(base), isTrue);
      expect(DashedRRectPainter(strokeWidth: 99).shouldRepaint(base), isTrue);
      expect(DashedRRectPainter(dashLength: 99).shouldRepaint(base), isTrue);
      expect(DashedRRectPainter(gapLength: 99).shouldRepaint(base), isTrue);
    });

    test('negative: does not repaint when all fields are equal', () {
      final a = DashedRRectPainter(
        color: const Color(0xFF123456),
        radius: 10,
        strokeWidth: 2,
        dashLength: 5,
        gapLength: 3,
      );
      final b = DashedRRectPainter(
        color: const Color(0xFF123456),
        radius: 10,
        strokeWidth: 2,
        dashLength: 5,
        gapLength: 3,
      );
      expect(b.shouldRepaint(a), isFalse);
    });
  });

  testWidgets('positive: renders inside a CustomPaint without error',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              size: const Size(120, 120),
              painter: DashedRRectPainter(),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
