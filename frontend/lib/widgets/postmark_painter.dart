import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter: dashed circle with stripes — used for postmark score display.
class PostmarkDashPainter extends CustomPainter {
  final Color color;
  PostmarkDashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final totalDashLen = dashWidth + dashSpace;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / totalDashLen).floor();

    canvas.save();
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (2 * math.pi / dashCount) * i;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        (2 * math.pi / dashCount) * (dashWidth / totalDashLen),
        false,
        paint,
      );
    }
    canvas.restore();

    final stripePaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const stripeGap = 4.0;
    final rect = Rect.fromCircle(center: center, radius: radius - 2);
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    for (double y = rect.top; y < rect.bottom; y += stripeGap * 2) {
      canvas.drawLine(
        Offset(rect.left, y + stripeGap),
        Offset(rect.right, y + stripeGap),
        stripePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
