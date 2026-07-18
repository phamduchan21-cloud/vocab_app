import 'dart:math' as math;

import 'package:flutter/material.dart';

class CatWidget extends StatelessWidget {
  const CatWidget({
    super.key,
    this.size = 120,
    this.expression = CatExpression.normal,
  });

  final double size;
  final CatExpression expression;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: _semanticLabel(expression),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _PostcatPainter(expression: expression)),
      ),
    );
  }

  String _semanticLabel(CatExpression value) {
    return switch (value) {
      CatExpression.happy => 'Mèo Sol vui vẻ',
      CatExpression.talking => 'Mèo Sol đang trò chuyện',
      CatExpression.love => 'Mèo Sol yêu thích',
      CatExpression.sad => 'Mèo Sol đang buồn',
      CatExpression.normal => 'Mèo Sol',
    };
  }
}

enum CatExpression { normal, happy, talking, love, sad }

class _PostcatPainter extends CustomPainter {
  const _PostcatPainter({required this.expression});

  final CatExpression expression;

  static const _fur = Color(0xFF358D87);
  static const _furLight = Color(0xFF67B8B0);
  static const _furDark = Color(0xFF174F4B);
  static const _cream = Color(0xFFFFF5E5);
  static const _coral = Color(0xFFEE6659);
  static const _pink = Color(0xFFFFA39B);
  static const _gold = Color(0xFFF5B940);
  static const _ink = Color(0xFF183B38);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 120;
    final dx = (size.width - 120 * scale) / 2;
    final dy = (size.height - 120 * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    _drawShadow(canvas);
    _drawTail(canvas);
    _drawBody(canvas);
    _drawHead(canvas);
    _drawFace(canvas);
    _drawScarf(canvas);
    _drawPaws(canvas);

    canvas.restore();
  }

  void _drawShadow(Canvas canvas) {
    canvas.drawOval(
      const Rect.fromLTWH(25, 106, 74, 9),
      Paint()..color = _ink.withValues(alpha: 0.11),
    );
  }

  void _drawTail(Canvas canvas) {
    final outline = Paint()
      ..color = _furDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = _fur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(85, 91)
      ..cubicTo(112, 98, 114, 66, 97, 65)
      ..cubicTo(89, 64, 90, 53, 100, 52);
    canvas.drawPath(path, outline);
    canvas.drawPath(path, fill);
    canvas.drawCircle(const Offset(100, 52), 4.9, Paint()..color = _cream);
  }

  void _drawBody(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(29, 59, 62, 51),
        const Radius.circular(28),
      ),
      Paint()..color = _furDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(32, 61, 56, 47),
        const Radius.circular(25),
      ),
      Paint()..color = _fur,
    );
    canvas.drawOval(
      const Rect.fromLTWH(45, 70, 30, 34),
      Paint()..color = _cream.withValues(alpha: 0.92),
    );

    final leftArm = Path()
      ..moveTo(38, 72)
      ..cubicTo(29, 83, 34, 96, 46, 98)
      ..cubicTo(50, 97, 51, 92, 47, 89)
      ..cubicTo(43, 84, 43, 78, 48, 74)
      ..close();
    final rightArm = Path()
      ..moveTo(82, 72)
      ..cubicTo(91, 83, 86, 96, 74, 98)
      ..cubicTo(70, 97, 69, 92, 73, 89)
      ..cubicTo(77, 84, 77, 78, 72, 74)
      ..close();
    canvas.drawPath(leftArm, Paint()..color = _furLight);
    canvas.drawPath(rightArm, Paint()..color = _furLight);
  }

  void _drawHead(Canvas canvas) {
    final leftEar = Path()
      ..moveTo(27, 31)
      ..quadraticBezierTo(22, 17, 30, 8)
      ..quadraticBezierTo(43, 13, 48, 22)
      ..close();
    final rightEar = Path()
      ..moveTo(93, 31)
      ..quadraticBezierTo(98, 17, 90, 8)
      ..quadraticBezierTo(77, 13, 72, 22)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = _furDark);
    canvas.drawPath(rightEar, Paint()..color = _furDark);

    final leftInner = Path()
      ..moveTo(29, 24)
      ..quadraticBezierTo(27, 16, 31, 12)
      ..quadraticBezierTo(39, 16, 42, 22)
      ..close();
    final rightInner = Path()
      ..moveTo(91, 24)
      ..quadraticBezierTo(93, 16, 89, 12)
      ..quadraticBezierTo(81, 16, 78, 22)
      ..close();
    canvas.drawPath(leftInner, Paint()..color = _pink);
    canvas.drawPath(rightInner, Paint()..color = _pink);

    canvas.drawOval(
      const Rect.fromLTWH(20, 17, 80, 61),
      Paint()..color = _furDark,
    );
    canvas.drawOval(const Rect.fromLTWH(23, 19, 74, 56), Paint()..color = _fur);

    final forehead = Path()
      ..moveTo(50, 21)
      ..quadraticBezierTo(53, 30, 56, 22)
      ..quadraticBezierTo(60, 31, 64, 22)
      ..quadraticBezierTo(67, 30, 70, 21);
    canvas.drawPath(
      forehead,
      Paint()
        ..color = _furLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawOval(
      const Rect.fromLTWH(39, 43, 42, 27),
      Paint()..color = _cream,
    );
  }

  void _drawFace(Canvas canvas) {
    if (expression == CatExpression.love) {
      _drawHeart(canvas, const Offset(44, 39), 8, _coral);
      _drawHeart(canvas, const Offset(76, 39), 8, _coral);
    } else if (expression == CatExpression.happy) {
      _drawHappyEye(canvas, const Offset(44, 40));
      _drawHappyEye(canvas, const Offset(76, 40));
    } else {
      _drawSparkleEye(
        canvas,
        const Offset(44, 39),
        sad: expression == CatExpression.sad,
      );
      _drawSparkleEye(
        canvas,
        const Offset(76, 39),
        sad: expression == CatExpression.sad,
      );
    }

    canvas.drawOval(
      const Rect.fromLTWH(29, 49, 15, 8),
      Paint()..color = _pink.withValues(alpha: 0.5),
    );
    canvas.drawOval(
      const Rect.fromLTWH(76, 49, 15, 8),
      Paint()..color = _pink.withValues(alpha: 0.5),
    );

    final nose = Path()
      ..moveTo(60, 49)
      ..cubicTo(55, 45, 52, 50, 60, 55)
      ..cubicTo(68, 50, 65, 45, 60, 49)
      ..close();
    canvas.drawPath(nose, Paint()..color = _coral);

    final mouthPaint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    switch (expression) {
      case CatExpression.talking:
        canvas.drawOval(
          const Rect.fromLTWH(53, 57, 14, 11),
          Paint()..color = _ink,
        );
        canvas.drawOval(
          const Rect.fromLTWH(56, 62, 8, 4),
          Paint()..color = _pink,
        );
      case CatExpression.sad:
        final frown = Path()
          ..moveTo(53, 64)
          ..quadraticBezierTo(60, 57, 67, 64);
        canvas.drawPath(frown, mouthPaint);
        final tear = Path()
          ..moveTo(82, 48)
          ..quadraticBezierTo(87, 55, 82, 58)
          ..quadraticBezierTo(77, 55, 82, 48)
          ..close();
        canvas.drawPath(tear, Paint()..color = const Color(0xFF71C9E8));
      default:
        final smile = Path()
          ..moveTo(50, 57)
          ..quadraticBezierTo(55, 64, 60, 58)
          ..quadraticBezierTo(65, 64, 70, 57);
        canvas.drawPath(smile, mouthPaint);
    }

    final whisker = Paint()
      ..color = _furDark.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(36, 55), const Offset(18, 52), whisker);
    canvas.drawLine(const Offset(36, 59), const Offset(17, 61), whisker);
    canvas.drawLine(const Offset(84, 55), const Offset(102, 52), whisker);
    canvas.drawLine(const Offset(84, 59), const Offset(103, 61), whisker);
  }

  void _drawSparkleEye(Canvas canvas, Offset center, {required bool sad}) {
    final eyeRect = Rect.fromCenter(
      center: center.translate(0, sad ? 2 : 0),
      width: 18,
      height: sad ? 16 : 20,
    );
    canvas.drawOval(eyeRect, Paint()..color = _cream);
    canvas.drawOval(eyeRect.deflate(3), Paint()..color = _ink);
    canvas.drawCircle(
      center.translate(-2.4, -3.2),
      2.8,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center.translate(3, 2.7),
      1.25,
      Paint()..color = Colors.white,
    );
    if (sad) {
      canvas.drawArc(
        Rect.fromCenter(center: center.translate(0, -8), width: 18, height: 9),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = _furDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawHappyEye(Canvas canvas, Offset center) {
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 17, height: 13),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawScarf(Canvas canvas) {
    final collar = RRect.fromRectAndRadius(
      const Rect.fromLTWH(36, 69, 48, 12),
      const Radius.circular(6),
    );
    canvas.drawRRect(collar, Paint()..color = _furDark);
    canvas.drawRRect(collar.deflate(2), Paint()..color = _coral);
    canvas.drawRect(const Rect.fromLTWH(48, 71, 5, 8), Paint()..color = _cream);
    canvas.drawRect(
      const Rect.fromLTWH(55, 71, 5, 8),
      Paint()..color = const Color(0xFF65B8CB),
    );
    canvas.drawRect(const Rect.fromLTWH(62, 71, 5, 8), Paint()..color = _cream);

    final scarfEnd = Path()
      ..moveTo(72, 77)
      ..lineTo(85, 84)
      ..lineTo(78, 89)
      ..lineTo(68, 78)
      ..close();
    canvas.drawPath(scarfEnd, Paint()..color = _coral);

    canvas.drawCircle(const Offset(60, 80), 6.5, Paint()..color = _furDark);
    canvas.drawCircle(const Offset(60, 80), 4.6, Paint()..color = _gold);
    canvas.drawCircle(
      const Offset(58.6, 78.4),
      1.2,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  void _drawPaws(Canvas canvas) {
    canvas.drawOval(
      const Rect.fromLTWH(31, 96, 29, 15),
      Paint()..color = _furDark,
    );
    canvas.drawOval(
      const Rect.fromLTWH(60, 96, 29, 15),
      Paint()..color = _furDark,
    );
    canvas.drawOval(
      const Rect.fromLTWH(34, 97, 25, 11),
      Paint()..color = _furLight,
    );
    canvas.drawOval(
      const Rect.fromLTWH(61, 97, 25, 11),
      Paint()..color = _furLight,
    );
    for (final x in [42.0, 50.0, 70.0, 78.0]) {
      canvas.drawCircle(
        Offset(x, 102),
        1.4,
        Paint()..color = _cream.withValues(alpha: 0.9),
      );
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size * 0.55)
      ..cubicTo(
        center.dx - size,
        center.dy,
        center.dx - size * 0.55,
        center.dy - size * 0.8,
        center.dx,
        center.dy - size * 0.2,
      )
      ..cubicTo(
        center.dx + size * 0.55,
        center.dy - size * 0.8,
        center.dx + size,
        center.dy,
        center.dx,
        center.dy + size * 0.55,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      center.translate(-size * 0.25, -size * 0.2),
      size * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(covariant _PostcatPainter oldDelegate) =>
      oldDelegate.expression != expression;
}
