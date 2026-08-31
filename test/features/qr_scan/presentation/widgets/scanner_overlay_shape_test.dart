import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/features/qr_scan/presentation/widgets/scanner_overlay_shape.dart';

void main() {
  void paint(CustomPainter painter, Size size) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, size);
    recorder.endRecording().dispose();
  }

  group('ScannerScrim', () {
    test('positive: paints the dimmed scrim with a clear window', () {
      expect(
        () => paint(ScannerScrim(windowSize: 200), const Size(400, 800)),
        returnsNormally,
      );
    });

    test('edge: window larger than the canvas still paints', () {
      expect(
        () => paint(ScannerScrim(windowSize: 9999), const Size(100, 100)),
        returnsNormally,
      );
    });

    test('edge: zero-size canvas does not throw', () {
      expect(
        () => paint(ScannerScrim(windowSize: 50), Size.zero),
        returnsNormally,
      );
    });

    test('positive: repaints when windowSize / radius / dimColor differ', () {
      final base = ScannerScrim(windowSize: 100);
      expect(ScannerScrim(windowSize: 200).shouldRepaint(base), isTrue);
      expect(
        ScannerScrim(windowSize: 100, radius: 8).shouldRepaint(base),
        isTrue,
      );
      expect(
        ScannerScrim(windowSize: 100, dimColor: const Color(0xFF000000))
            .shouldRepaint(base),
        isTrue,
      );
    });

    test('negative: does not repaint when identical', () {
      final a = ScannerScrim(windowSize: 100, radius: 16);
      final b = ScannerScrim(windowSize: 100, radius: 16);
      expect(b.shouldRepaint(a), isFalse);
    });
  });

  group('ScannerOverlayShape', () {
    test('positive: paints the four corner brackets without throwing', () {
      expect(
        () => paint(ScannerOverlayShape(), const Size(240, 240)),
        returnsNormally,
      );
    });

    test('edge: paints on a tiny canvas smaller than the brackets', () {
      expect(
        () => paint(ScannerOverlayShape(), const Size(10, 10)),
        returnsNormally,
      );
    });

    test('negative: shouldRepaint is always false (static brackets)', () {
      final a = ScannerOverlayShape();
      final b = ScannerOverlayShape();
      expect(a.shouldRepaint(b), isFalse);
    });
  });

  testWidgets('positive: both painters render inside a CustomPaint',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              CustomPaint(
                size: const Size(300, 300),
                painter: ScannerScrim(windowSize: 180),
              ),
              CustomPaint(
                size: const Size(180, 180),
                painter: ScannerOverlayShape(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
