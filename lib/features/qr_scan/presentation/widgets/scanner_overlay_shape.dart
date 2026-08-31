import 'package:flutter/material.dart';

import 'package:rewardhub/core/theme/app_colors.dart';

/// Dims the entire camera area except for a centered rounded "window", giving
/// the classic scanner look that focuses attention on the scan target.
class ScannerScrim extends CustomPainter {
  ScannerScrim({
    required this.windowSize,
    this.radius = 16,
    this.dimColor = const Color(0x99000000),
  });

  /// Side length of the clear square window at the center.
  final double windowSize;

  /// Corner radius of the window (matches the corner brackets).
  final double radius;

  /// Color of the dimmed area outside the window.
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final window = Rect.fromCenter(
      center: full.center,
      width: windowSize,
      height: windowSize,
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      Path()
        ..addRRect(RRect.fromRectAndRadius(window, Radius.circular(radius))),
    );
    canvas.drawPath(path, Paint()..color = dimColor);
  }

  @override
  bool shouldRepaint(covariant ScannerScrim oldDelegate) =>
      oldDelegate.windowSize != windowSize ||
      oldDelegate.radius != radius ||
      oldDelegate.dimColor != dimColor;
}

/// Draws the four rounded corner brackets that frame the scan area.
class ScannerOverlayShape extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double length = 40.0;
    const double r = 16.0;

    var path = Path()
      ..moveTo(0, length)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(length, 0);
    canvas.drawPath(path, paint);

    path = Path()
      ..moveTo(size.width - length, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, length);
    canvas.drawPath(path, paint);

    path = Path()
      ..moveTo(0, size.height - length)
      ..lineTo(0, size.height - r)
      ..quadraticBezierTo(0, size.height, r, size.height)
      ..lineTo(length, size.height);
    canvas.drawPath(path, paint);

    path = Path()
      ..moveTo(size.width - length, size.height)
      ..lineTo(size.width - r, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - r)
      ..lineTo(size.width, size.height - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
