import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/quiz_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/postmark_painter.dart';

class QuizResultScreen extends StatelessWidget {
  final String id;

  const QuizResultScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final result = quiz.lastResult;

    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Kết quả',
            style: GoogleFonts.workSans(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: AppColors.ink,
            ),
          ),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => context.go('/quiz'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('\u{1F4ED}', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                'Không có kết quả cho bài quiz này',
                style: GoogleFonts.workSans(fontSize: 16, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('Quay lại', style: GoogleFonts.workSans(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      );
    }

    final scorePercent = result.scorePercent;
    final isGood = scorePercent >= 80;
    final isMedium = scorePercent >= 50;
    final color = isGood
        ? AppColors.success
        : isMedium
            ? AppColors.warning
            : AppColors.danger;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      appBar: AppBar(
        title: Text(
          'Kết quả',
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.go('/quiz'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 60),
        child: Column(
          children: [
            // Postmark score circle
            _PostmarkScore(
              score: result.correctAnswers,
              total: result.totalQuestions,
              color: color,
            ),
            const SizedBox(height: 20),

            // Message
            Text(
              isGood
                  ? 'Xuất sắc!'
                  : isMedium
                      ? 'Cố gắng hơn nhé!'
                      : 'Cần ôn tập thêm!',
              style: GoogleFonts.workSans(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.quizType,
              style: GoogleFonts.workSans(
                fontSize: 15,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 28),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ResultStat(
                  value: '${result.correctAnswers}',
                  label: 'Đúng',
                  color: AppColors.success,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  width: 1,
                  height: 40,
                  color: AppColors.ink.withValues(alpha: 0.10),
                ),
                _ResultStat(
                  value: '${result.totalQuestions - result.correctAnswers}',
                  label: 'Sai',
                  color: AppColors.danger,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  width: 1,
                  height: 40,
                  color: AppColors.ink.withValues(alpha: 0.10),
                ),
                _ResultStat(
                  value: '${result.scorePercent.round()}%',
                  label: 'Điểm',
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Details section
            if (result.details != null && result.details!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.ink.withValues(alpha: 0.14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết đáp án',
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...result.details!.asMap().entries.map((entry) {
                      final detail = entry.value as Map<String, dynamic>;
                      final isCorrect =
                          detail['selected'] == detail['correctAnswer'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.success.withValues(alpha: 0.06)
                              : AppColors.danger.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: isCorrect
                                  ? AppColors.success
                                  : AppColors.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Câu ${entry.key + 1}',
                                    style: GoogleFonts.workSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Bạn chọn: ${detail['selected'] ?? 'Chưa chọn'}',
                                    style: GoogleFonts.workSans(
                                      fontSize: 13,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                  Text(
                                    'Đáp án: ${detail['correctAnswer']}',
                                    style: GoogleFonts.workSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isCorrect
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/quiz'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkSoft,
                      side: BorderSide(
                        color: AppColors.ink.withValues(alpha: 0.14),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Làm lại',
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Về trang chủ',
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// POSTMARK SCORE CIRCLE
// ═══════════════════════════════════════════════════════════════════════════════

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
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        color: AppColors.surface,
      ),
      child: CustomPaint(
        painter: PostmarkDashPainter(color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '/ $total đúng',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: color,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PostmarkDashPainter moved to widgets/postmark_painter.dart

// ═══════════════════════════════════════════════════════════════════════════════
// RESULT STAT WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _ResultStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ResultStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
