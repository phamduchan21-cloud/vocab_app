import 'dart:math' as math;

import 'package:flutter/material.dart';

class CosmicBackground extends StatelessWidget {
  final Widget child;

  const CosmicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF070B17), Color(0xFF0C1530), Color(0xFF10182D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(child: CustomPaint(painter: _StarFieldPainter())),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.85, -0.8),
                  radius: 0.8,
                  colors: [
                    const Color(0xFF55D9EA).withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, 0.75),
                  radius: 0.72,
                  colors: [
                    const Color(0xFFFF7A66).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7319);
    final starPaint = Paint();
    for (var index = 0; index < 90; index++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = index % 13 == 0
          ? 1.35
          : index % 5 == 0
          ? 0.9
          : 0.48;
      starPaint.color = Colors.white.withValues(
        alpha: 0.16 + random.nextDouble() * 0.42,
      );
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }

    final orbitPaint = Paint()
      ..color = const Color(0xFF55D9EA).withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.82, size.height * 0.18),
        width: size.width * 0.72,
        height: size.width * 0.24,
      ),
      orbitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => false;
}
