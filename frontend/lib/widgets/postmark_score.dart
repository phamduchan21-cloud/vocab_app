import 'package:flutter/material.dart';

/// Custom painter: dashed arc — used for postmark score display.
class PostmarkDashPainter extends CustomPainter {
  final Color color;
  PostmarkDashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 4;
    double startAngle = -1.2;
    const arcSweep = 2.4;
    final totalArcLength = radius * arcSweep;
    final totalDash = dashWidth + dashSpace;
    final dashCount = (totalArcLength / totalDash).floor();
    for (int i = 0; i < dashCount; i++) {
      final start = startAngle + (i * totalDash) / radius;
      final end = start + dashWidth / radius;
      canvas.drawArc(Rect.fromCenter(center: center, width: radius * 2, height: radius * 2), start, end - start, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PostmarkDashPainter old) => old.color != color;
}

/// Simple score display with dashed arc decoration — used in quiz & mock-test results.
class PostmarkScore extends StatelessWidget {
  final int score;
  final String label;
  final Color color;
  const PostmarkScore({super.key, required this.score, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(painter: PostmarkDashPainter(color: color), size: const Size(120, 120)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
