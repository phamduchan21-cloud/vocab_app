import 'package:flutter/material.dart';
import '../app.dart';

class CatWidget extends StatelessWidget {
  final double size;
  final CatExpression expression;

  const CatWidget({
    super.key,
    this.size = 120,
    this.expression = CatExpression.normal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CatPainter(expression: expression),
      ),
    );
  }
}

enum CatExpression {
  normal,
  happy,
  talking,
  love,
  sad,
}

class _CatPainter extends CustomPainter {
  final CatExpression expression;

  _CatPainter({this.expression = CatExpression.normal});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120;
    final purple = AppColors.lavender;
    final pink = AppColors.lavender;
    final darkPurple = const Color(0xFF5B21B6);
    final white = Colors.white;
    final lightPurple = AppColors.rose.withValues(alpha: 0.10);

    // === Body ===
    final bodyPaint = Paint()..color = purple;

    // Body (oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(60 * scale, 80 * scale), width: 70 * scale, height: 55 * scale),
      bodyPaint,
    );

    // Belly (lighter)
    final bellyPaint = Paint()..color = lightPurple;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(60 * scale, 82 * scale), width: 40 * scale, height: 30 * scale),
      bellyPaint,
    );

    // === Head ===
    final headPaint = Paint()..color = purple;

    // Main head circle
    canvas.drawCircle(Offset(60 * scale, 35 * scale), 30 * scale, headPaint);

    // === Ears ===
    final earPath = Path()
      ..moveTo(38 * scale, 20 * scale)
      ..lineTo(28 * scale, 0 * scale)
      ..lineTo(48 * scale, 10 * scale)
      ..close();
    canvas.drawPath(earPath, headPaint);

    final earPath2 = Path()
      ..moveTo(82 * scale, 20 * scale)
      ..lineTo(92 * scale, 0 * scale)
      ..lineTo(72 * scale, 10 * scale)
      ..close();
    canvas.drawPath(earPath2, headPaint);

    // Inner ears (pink)
    final innerEarPaint = Paint()..color = pink;
    final innerEarPath = Path()
      ..moveTo(40 * scale, 18 * scale)
      ..lineTo(33 * scale, 4 * scale)
      ..lineTo(47 * scale, 12 * scale)
      ..close();
    canvas.drawPath(innerEarPath, innerEarPaint);

    final innerEarPath2 = Path()
      ..moveTo(80 * scale, 18 * scale)
      ..lineTo(87 * scale, 4 * scale)
      ..lineTo(73 * scale, 12 * scale)
      ..close();
    canvas.drawPath(innerEarPath2, innerEarPaint);

    // === Eyes ===
    // White of eyes
    final eyeWhitePaint = Paint()..color = white;
    canvas.drawCircle(Offset(47 * scale, 32 * scale), 8 * scale, eyeWhitePaint);
    canvas.drawCircle(Offset(73 * scale, 32 * scale), 8 * scale, eyeWhitePaint);

    // Pupils
    final pupilPaint = Paint()..color = darkPurple;
    canvas.drawCircle(Offset(47 * scale, 32 * scale), 4.5 * scale, pupilPaint);
    canvas.drawCircle(Offset(73 * scale, 32 * scale), 4.5 * scale, pupilPaint);

    // Eye shine
    final shinePaint = Paint()..color = white;
    canvas.drawCircle(Offset(44 * scale, 29 * scale), 2.5 * scale, shinePaint);
    canvas.drawCircle(Offset(70 * scale, 29 * scale), 2.5 * scale, shinePaint);

    // === Eyes expression ===
    switch (expression) {
      case CatExpression.happy:
        // Squeezed happy eyes (arcs)
        canvas.drawCircle(Offset(47 * scale, 32 * scale), 8 * scale, eyeWhitePaint);
        canvas.drawCircle(Offset(73 * scale, 32 * scale), 8 * scale, eyeWhitePaint);
        canvas.drawCircle(Offset(47 * scale, 32 * scale), 4.5 * scale, pupilPaint);
        canvas.drawCircle(Offset(73 * scale, 32 * scale), 4.5 * scale, pupilPaint);
        canvas.drawCircle(Offset(44 * scale, 29 * scale), 2.5 * scale, shinePaint);
        canvas.drawCircle(Offset(70 * scale, 29 * scale), 2.5 * scale, shinePaint);
        break;
      case CatExpression.love:
        // Heart eyes
        _drawHeart(canvas, Offset(47 * scale, 33 * scale), 6 * scale, pink);
        _drawHeart(canvas, Offset(73 * scale, 33 * scale), 6 * scale, pink);
        break;
      case CatExpression.talking:
        // Normal eyes, slightly wider
        canvas.drawCircle(Offset(47 * scale, 31 * scale), 9 * scale, eyeWhitePaint);
        canvas.drawCircle(Offset(73 * scale, 31 * scale), 9 * scale, eyeWhitePaint);
        canvas.drawCircle(Offset(47 * scale, 31 * scale), 5 * scale, pupilPaint);
        canvas.drawCircle(Offset(73 * scale, 31 * scale), 5 * scale, pupilPaint);
        canvas.drawCircle(Offset(44 * scale, 28 * scale), 2.5 * scale, shinePaint);
        canvas.drawCircle(Offset(70 * scale, 28 * scale), 2.5 * scale, shinePaint);
        break;
      case CatExpression.sad:
        // Closed sad eyes (half circle)
        final sadEyePaint = Paint()..color = purple;
        final sadPath = Path()
          ..moveTo(39 * scale, 32 * scale)
          ..quadraticBezierTo(47 * scale, 38 * scale, 55 * scale, 32 * scale)
          ..close();
        canvas.drawPath(sadPath, sadEyePaint);
        final sadPath2 = Path()
          ..moveTo(65 * scale, 32 * scale)
          ..quadraticBezierTo(73 * scale, 38 * scale, 81 * scale, 32 * scale)
          ..close();
        canvas.drawPath(sadPath2, sadEyePaint);
        break;
      default:
        // Normal — already drawn above
        break;
    }

    // === Nose (pink) ===
    final nosePaint = Paint()..color = pink;
    final nosePath = Path()
      ..moveTo(60 * scale, 38 * scale)
      ..lineTo(56 * scale, 42 * scale)
      ..lineTo(64 * scale, 42 * scale)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // === Mouth ===
    final mouthPaint = Paint()
      ..color = darkPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;

    switch (expression) {
      case CatExpression.happy:
        // Big happy smile
        final smilePath = Path()
          ..moveTo(50 * scale, 44 * scale)
          ..quadraticBezierTo(60 * scale, 54 * scale, 70 * scale, 44 * scale);
        canvas.drawPath(smilePath, mouthPaint);
        // Cheek blush
        final blushPaint = Paint()..color = pink.withValues(alpha: 0.3);
        canvas.drawCircle(Offset(40 * scale, 44 * scale), 5 * scale, blushPaint);
        canvas.drawCircle(Offset(80 * scale, 44 * scale), 5 * scale, blushPaint);
        break;
      case CatExpression.talking:
        // Open mouth (talking)
        final openMouthPaint = Paint()..color = darkPurple;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(60 * scale, 48 * scale), width: 14 * scale, height: 10 * scale),
          openMouthPaint,
        );
        break;
      case CatExpression.sad:
        // Sad frown
        final sadMouthPath = Path()
          ..moveTo(50 * scale, 48 * scale)
          ..quadraticBezierTo(60 * scale, 44 * scale, 70 * scale, 48 * scale);
        canvas.drawPath(sadMouthPath, mouthPaint);
        break;
      default:
        // Normal small smile
        final normalMouthPath = Path()
          ..moveTo(54 * scale, 44 * scale)
          ..quadraticBezierTo(60 * scale, 48 * scale, 66 * scale, 44 * scale);
        canvas.drawPath(normalMouthPath, mouthPaint);
        break;
    }

    // === Whiskers ===
    final whiskerPaint = Paint()
      ..color = darkPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;

    // Left whiskers
    canvas.drawLine(Offset(40 * scale, 40 * scale), Offset(22 * scale, 36 * scale), whiskerPaint);
    canvas.drawLine(Offset(40 * scale, 43 * scale), Offset(20 * scale, 44 * scale), whiskerPaint);
    canvas.drawLine(Offset(40 * scale, 46 * scale), Offset(22 * scale, 52 * scale), whiskerPaint);

    // Right whiskers
    canvas.drawLine(Offset(80 * scale, 40 * scale), Offset(98 * scale, 36 * scale), whiskerPaint);
    canvas.drawLine(Offset(80 * scale, 43 * scale), Offset(100 * scale, 44 * scale), whiskerPaint);
    canvas.drawLine(Offset(80 * scale, 46 * scale), Offset(98 * scale, 52 * scale), whiskerPaint);

    // === Paws ===
    final pawPaint = Paint()..color = purple;
    // Left paw
    canvas.drawOval(
      Rect.fromCenter(center: Offset(38 * scale, 98 * scale), width: 18 * scale, height: 12 * scale),
      pawPaint,
    );
    // Right paw
    canvas.drawOval(
      Rect.fromCenter(center: Offset(82 * scale, 98 * scale), width: 18 * scale, height: 12 * scale),
      pawPaint,
    );

    // Paw pads (pink)
    final padPaint = Paint()..color = pink;
    canvas.drawCircle(Offset(38 * scale, 98 * scale), 3 * scale, padPaint);
    canvas.drawCircle(Offset(82 * scale, 98 * scale), 3 * scale, padPaint);

    // === Tail ===
    final tailPaint = Paint()
      ..color = purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * scale
      ..strokeCap = StrokeCap.round;
    final tailPath = Path()
      ..moveTo(30 * scale, 90 * scale)
      ..quadraticBezierTo(0 * scale, 70 * scale, 10 * scale, 50 * scale)
      ..quadraticBezierTo(18 * scale, 38 * scale, 16 * scale, 30 * scale);
    canvas.drawPath(tailPath, tailPaint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(center.dx, center.dy - size * 0.25)
      ..cubicTo(
        center.dx - size * 0.6, center.dy - size * 0.8,
        center.dx - size, center.dy + size * 0.2,
        center.dx, center.dy + size * 0.5,
      )
      ..cubicTo(
        center.dx + size, center.dy + size * 0.2,
        center.dx + size * 0.6, center.dy - size * 0.8,
        center.dx, center.dy - size * 0.25,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CatPainter oldDelegate) {
    return oldDelegate.expression != expression;
  }
}
