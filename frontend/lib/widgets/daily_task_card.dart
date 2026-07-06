import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';

class DailyTaskCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final String? meta;
  final bool isDone;
  final Color accentColor;
  final double progress; // 0.0 - 1.0
  final VoidCallback onTap;

  const DailyTaskCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    this.meta,
    this.isDone = false,
    this.accentColor = AppColors.blue,
    this.progress = 0.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDone
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isDone ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone
                    ? AppColors.success.withValues(alpha: 0.25)
                    : AppColors.ink.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                // Left: Emoji icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success.withValues(alpha: 0.12)
                        : accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      isDone ? '✅' : emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Middle: Title + Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.workSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDone ? AppColors.success : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDone ? 'Đã hoàn thành ✓' : description,
                        style: GoogleFonts.workSans(
                          fontSize: 12,
                          color: isDone
                              ? AppColors.success
                              : AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Progress ring or Meta
                if (isDone)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.check, size: 18, color: AppColors.success),
                  )
                else if (progress > 0)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: progress,
                        color: accentColor,
                      ),
                      child: Center(
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (meta != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      meta!,
                      style: GoogleFonts.workSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.inkSoft,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
