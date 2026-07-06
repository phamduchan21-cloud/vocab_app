import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../app.dart';
import '../models/mock_test.dart';

class MockTestResultScreen extends StatelessWidget {
  final MockTestResult result;

  const MockTestResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result.scorePercent;
    final grade = _calculateGrade(score);
    final level = _englishLevel(score);
    final levelColor = _levelColor(level);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kết quả thi thử',
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.ink),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 60),
        child: Column(
          children: [
            // ── Postmark score circle ──────────────────────
            _PostmarkScore(
              score: result.scorePercent.round(),
              total: result.totalQuestions,
              color: levelColor,
            ),
            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────
            Text(
              'Hoàn thành bài kiểm tra!',
              style: GoogleFonts.workSans(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bạn đạt trình độ $level',
              style: GoogleFonts.workSans(
                fontSize: 15,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 24),

            // ── Stats row ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('📝', '${result.totalQuestions}', 'Tổng câu'),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.ink.withValues(alpha: 0.10),
                  ),
                  _statItem('✅', '${result.correctAnswers}', 'Đúng'),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.ink.withValues(alpha: 0.10),
                  ),
                  _statItem('❌',
                      '${result.totalQuestions - result.correctAnswers}',
                      'Sai'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Level info card ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: levelColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: levelColor.withValues(alpha: 0.12),
                      border: Border.all(color: levelColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        grade,
                        style: GoogleFonts.workSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: levelColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trình độ $level · Xếp loại $grade',
                          style: GoogleFonts.workSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _levelDescription(level),
                          style: GoogleFonts.workSans(
                            fontSize: 13,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Actions ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: Text(
                      'Về trang chủ',
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkSoft,
                      side: BorderSide(
                        color: AppColors.ink.withValues(alpha: 0.14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/test'),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      'Làm lại',
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 12,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateGrade(double percent) {
    if (percent >= 90) return 'A';
    if (percent >= 75) return 'B';
    if (percent >= 50) return 'C';
    return 'D';
  }

  String _englishLevel(double percent) {
    if (percent >= 90) return 'C1';
    if (percent >= 75) return 'B2';
    if (percent >= 60) return 'B1';
    if (percent >= 40) return 'A2';
    return 'A1';
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'C1':
        return AppColors.success;
      case 'B2':
        return AppColors.blue;
      case 'B1':
        return AppColors.warning;
      case 'A2':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  String _levelDescription(String level) {
    switch (level) {
      case 'C1':
        return 'Trình độ cao cấp — Có thể giao tiếp trôi chảy trong mọi tình huống.';
      case 'B2':
        return 'Trình độ trung cao cấp — Có thể sử dụng ngôn ngữ thành thạo.';
      case 'B1':
        return 'Trình độ trung cấp — Có thể giao tiếp cơ bản trong sinh hoạt.';
      case 'A2':
        return 'Trình độ sơ cấp — Có thể giao tiếp đơn giản.';
      default:
        return 'Trình độ mới bắt đầu — Làm quen với ngôn ngữ.';
    }
  }
}

// ─── POSTMARK SCORE CIRCLE ───────────────────────────────────────

class _PostmarkScore extends StatelessWidget {
  final int score;
  final int total;
  final Color color;

  const _PostmarkScore({
    required this.score,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        color: AppColors.surface,
      ),
      child: CustomPaint(
        painter: _PostmarkDashPainter(color: color),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Text(
              '$score%',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$total câu',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: color.withValues(alpha: 0.7),
                height: 1.0,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _PostmarkDashPainter extends CustomPainter {
  final Color color;

  _PostmarkDashPainter({required this.color});

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
