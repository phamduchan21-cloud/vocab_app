import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app.dart';

const solvocabLogoHeroTag = 'solvocab-brand-logo';

class AppLogoHero extends StatelessWidget {
  const AppLogoHero({
    super.key,
    this.size = 72,
    this.showName = false,
    this.light = false,
  });

  final double size;
  final bool showName;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: solvocabLogoHeroTag,
      transitionOnUserGestures: true,
      child: Material(
        type: MaterialType.transparency,
        child: AppLogo(size: size, showName: showName, light: light),
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.showName = false,
    this.light = false,
  });

  final double size;
  final bool showName;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final mark = Semantics(
      image: true,
      label: 'Logo SolVocab',
      child: CustomPaint(
        size: Size.square(size),
        painter: _SolVocabLogoPainter(light: light),
      ),
    );

    if (!showName) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SolVocab',
              style: GoogleFonts.spaceGrotesk(
                color: light ? Colors.white : AppColors.luxuryEspresso,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.34,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
            Text(
              'HỌC · KHÁM PHÁ · LÀM CHỦ',
              style: GoogleFonts.ibmPlexMono(
                color: light
                    ? Colors.white.withValues(alpha: 0.78)
                    : AppColors.luxuryText,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.65,
                fontSize: size * 0.092,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SolVocabLogoPainter extends CustomPainter {
  const _SolVocabLogoPainter({required this.light});

  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 100;
    final bounds = Rect.fromLTWH(7 * unit, 7 * unit, 86 * unit, 86 * unit);
    final shell = RRect.fromRectAndRadius(bounds, Radius.circular(27 * unit));
    final shellPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1B2E59), Color(0xFF0A1022)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds);
    canvas.drawRRect(shell, shellPaint);
    canvas.drawRRect(
      shell.deflate(1.5 * unit),
      Paint()
        ..color = (light ? Colors.white : AppColors.blue).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * unit,
    );

    // A tilted orbit makes the mark recognizable even at favicon size.
    canvas.save();
    canvas.translate(50 * unit, 51 * unit);
    canvas.rotate(-0.34);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 82 * unit, height: 31 * unit),
      Paint()
        ..color = const Color(0xFF55D9EA).withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * unit,
    );
    canvas.drawCircle(
      Offset(39 * unit, 0),
      5.2 * unit,
      Paint()..color = const Color(0xFFFFC857),
    );
    canvas.restore();

    final helmetCenter = Offset(50 * unit, 49 * unit);
    canvas.drawCircle(
      helmetCenter,
      29 * unit,
      Paint()..color = const Color(0xFFCCF7FF).withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      helmetCenter,
      28.5 * unit,
      Paint()
        ..color = const Color(0xFF9DECF4).withValues(alpha: 0.66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * unit,
    );

    final earPaint = Paint()..color = const Color(0xFF203B63);
    canvas.drawPath(
      Path()
        ..moveTo(30 * unit, 40 * unit)
        ..lineTo(34 * unit, 22 * unit)
        ..lineTo(45 * unit, 35 * unit)
        ..close(),
      earPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(55 * unit, 35 * unit)
        ..lineTo(66 * unit, 22 * unit)
        ..lineTo(70 * unit, 40 * unit)
        ..close(),
      earPaint,
    );
    final face = RRect.fromRectAndRadius(
      Rect.fromLTWH(28 * unit, 33 * unit, 44 * unit, 36 * unit),
      Radius.circular(18 * unit),
    );
    canvas.drawRRect(face, Paint()..color = const Color(0xFFEAF7F7));

    final eyePaint = Paint()..color = const Color(0xFF0A1830);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(40 * unit, 50 * unit),
        width: 5 * unit,
        height: 7 * unit,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(60 * unit, 50 * unit),
        width: 5 * unit,
        height: 7 * unit,
      ),
      eyePaint,
    );
    canvas.drawCircle(
      Offset(50 * unit, 58 * unit),
      2.6 * unit,
      Paint()..color = const Color(0xFFFF7A66),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(46.8 * unit, 61 * unit),
        width: 7 * unit,
        height: 5 * unit,
      ),
      0,
      2.6,
      false,
      Paint()
        ..color = const Color(0xFF203B63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * unit,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(53.2 * unit, 61 * unit),
        width: 7 * unit,
        height: 5 * unit,
      ),
      0.54,
      2.6,
      false,
      Paint()
        ..color = const Color(0xFF203B63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * unit,
    );

    canvas.drawCircle(
      Offset(76 * unit, 22 * unit),
      2.4 * unit,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(23 * unit, 72 * unit),
      1.6 * unit,
      Paint()..color = const Color(0xFF7FA8FF),
    );
  }

  @override
  bool shouldRepaint(covariant _SolVocabLogoPainter oldDelegate) =>
      oldDelegate.light != light;
}
