import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/quiz_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/postmark_painter.dart';

const _entryCurve = Cubic(0.34, 1.56, 0.64, 1);

class QuizResultScreen extends StatefulWidget {
  final String id;

  const QuizResultScreen({super.key, required this.id});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: _entryCurve);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: _entryCurve));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final result = quiz.lastResult;

    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.luxuryBg,
        appBar: AppBar(
          backgroundColor: AppColors.luxurySurface,
          foregroundColor: AppColors.luxuryEspresso,
          title: Text(
            'Kết quả',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: AppColors.luxuryEspresso,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.luxuryEspresso),
            onPressed: () => context.go('/quiz'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('\u{1F4ED}', style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                'Không có kết quả cho bài quiz này',
                style: GoogleFonts.nunito(fontSize: 16, color: AppColors.luxuryText),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.luxuryGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => context.go('/quiz'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Quay lại',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
        ? AppColors.luxuryGreen
        : isMedium
            ? AppColors.luxuryGold
            : AppColors.luxuryDanger;

    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      appBar: AppBar(
        backgroundColor: AppColors.luxurySurface,
        foregroundColor: AppColors.luxuryEspresso,
        scrolledUnderElevation: 0,
        title: Text(
          'Kết quả',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppColors.luxuryEspresso,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.luxuryEspresso),
          onPressed: () => context.go('/quiz'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 60),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
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
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.quizType,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: AppColors.luxuryText,
                  ),
                ),
                const SizedBox(height: 28),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ResultStat(value: '${result.correctAnswers}', label: 'Đúng', color: AppColors.luxuryGreen),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      width: 1.5,
                      height: 40,
                      color: AppColors.luxuryBorder,
                    ),
                    _ResultStat(
                      value: '${result.totalQuestions - result.correctAnswers}',
                      label: 'Sai',
                      color: AppColors.luxuryDanger,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      width: 1.5,
                      height: 40,
                      color: AppColors.luxuryBorder,
                    ),
                    _ResultStat(
                      value: '${result.scorePercent.round()}%',
                      label: 'Điểm',
                      color: AppColors.luxuryGold,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Details section
                if (result.details != null && result.details!.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.luxuryBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.luxurySurface,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chi tiết đáp án',
                            style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.luxuryEspresso,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...result.details!.asMap().entries.map((entry) {
                            final detail = entry.value as Map<String, dynamic>;
                            final isCorrect = detail['selected'] == detail['correctAnswer'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? AppColors.luxuryGreen.withValues(alpha: 0.06)
                                    : AppColors.luxuryDanger.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCorrect
                                      ? AppColors.luxuryGreen.withValues(alpha: 0.3)
                                      : AppColors.luxuryDanger.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                    color: isCorrect ? AppColors.luxuryGreen : AppColors.luxuryDanger,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Câu ${entry.key + 1}',
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppColors.luxuryEspresso,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Bạn chọn: ${detail['selected'] ?? 'Chưa chọn'}',
                                          style: GoogleFonts.nunito(fontSize: 13, color: AppColors.luxuryText),
                                        ),
                                        Text(
                                          'Đáp án: ${detail['correctAnswer']}',
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isCorrect ? AppColors.luxuryGreen : AppColors.luxuryDanger,
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
                  ),

                const SizedBox(height: 28),

                // Actions — button-in-button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
                        ),
                        child: Material(
                          color: AppColors.luxurySurface,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => context.go('/quiz'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'Làm lại',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.luxuryBrown,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.luxuryGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => context.go('/'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Về trang chủ',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.home_rounded, size: 14, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        color: AppColors.luxurySurface,
      ),
      child: CustomPaint(
        painter: PostmarkDashPainter(color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '/ $total đúng',
                style: GoogleFonts.nunito(
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
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.luxuryText,
          ),
        ),
      ],
    );
  }
}
