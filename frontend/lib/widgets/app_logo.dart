import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app.dart';

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
              style: GoogleFonts.playfairDisplay(
                color: light ? Colors.white : AppColors.luxuryEspresso,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.34,
                height: 1,
              ),
            ),
            Text(
              'GỬI TỪ MỚI · NHẬN TIẾN BỘ',
              style: GoogleFonts.nunito(
                color: light
                    ? Colors.white.withValues(alpha: 0.78)
                    : AppColors.luxuryText,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.05,
                fontSize: size * 0.105,
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
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(7 * unit, 7 * unit, 86 * unit, 86 * unit),
      Radius.circular(18 * unit),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..color = light ? const Color(0xFFFFF8EC) : const Color(0xFFFFF7E8),
    );

    final border = Paint()
      ..color = const Color(0xFFE95F52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * unit;
    canvas.drawRRect(outer.deflate(4 * unit), border);

    final cutout = Paint()
      ..color = light ? const Color(0xFF1F5F5A) : AppColors.luxuryBg;
    for (var i = 0; i < 7; i++) {
      final offset = (18 + i * 10.7) * unit;
      canvas.drawCircle(Offset(offset, 7 * unit), 2.5 * unit, cutout);
      canvas.drawCircle(Offset(offset, 93 * unit), 2.5 * unit, cutout);
      canvas.drawCircle(Offset(7 * unit, offset), 2.5 * unit, cutout);
      canvas.drawCircle(Offset(93 * unit, offset), 2.5 * unit, cutout);
    }

    final envelope = Path()
      ..moveTo(24 * unit, 34 * unit)
      ..lineTo(76 * unit, 34 * unit)
      ..lineTo(76 * unit, 68 * unit)
      ..lineTo(24 * unit, 68 * unit)
      ..close();
    canvas.drawPath(envelope, Paint()..color = const Color(0xFF0D716B));
    canvas.drawPath(
      Path()
        ..moveTo(24 * unit, 36 * unit)
        ..lineTo(50 * unit, 56 * unit)
        ..lineTo(76 * unit, 36 * unit),
      Paint()
        ..color = const Color(0xFFFFF7E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * unit
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(25 * unit, 67 * unit)
        ..lineTo(43 * unit, 51 * unit)
        ..moveTo(75 * unit, 67 * unit)
        ..lineTo(57 * unit, 51 * unit),
      Paint()
        ..color = const Color(0xFFFFF7E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * unit,
    );

    final stamp = Paint()..color = const Color(0xFFF5B940);
    canvas.drawCircle(Offset(69 * unit, 69 * unit), 13 * unit, stamp);
    final sPainter = TextPainter(
      text: TextSpan(
        text: 'S',
        style: TextStyle(
          color: const Color(0xFF713B2E),
          fontSize: 16 * unit,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    sPainter.paint(
      canvas,
      Offset(69 * unit - sPainter.width / 2, 69 * unit - sPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SolVocabLogoPainter oldDelegate) =>
      oldDelegate.light != light;
}
