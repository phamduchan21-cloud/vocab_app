import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/quiz_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/cat_widget.dart';

class QuizResultScreen extends StatelessWidget {
  final String id;

  const QuizResultScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final result = quiz.lastResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kết quả')),
        body: const LoadingWidget(),
      );
    }

    final scorePercent = result.scorePercent;
    final isGood = scorePercent >= 80;
    final isMedium = scorePercent >= 50;
    final color = isGood
        ? AppColors.primary
        : isMedium
            ? AppColors.accent1
            : AppColors.accent2;
    final message = isGood
        ? 'Xuất sắc!'
        : isMedium
            ? 'Cố gắng hơn nhé!'
            : 'Cần ôn tập thêm!';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Mèo celebration
            if (isGood)
              const CatWidget(size: 100, expression: CatExpression.love)
            else
              const CatWidget(size: 100, expression: CatExpression.normal),
            const SizedBox(height: 16),
            // Message
            Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.quizType,
              style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            // Score ring
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: scorePercent / 100),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 10,
                          backgroundColor: const Color(0xFFF3F4F6),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          strokeCap: StrokeCap.round,
                        );
                      },
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${scorePercent.toStringAsFixed(0)}%',
                        style: GoogleFonts.nunito(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        '${result.correctAnswers}/${result.totalQuestions}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Đúng', '${result.correctAnswers}', AppColors.primary),
                _buildStatItem('Sai', '${result.totalQuestions - result.correctAnswers}', AppColors.accent2),
                _buildStatItem('Tổng', '${result.totalQuestions}', AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 24),
            // Details
            if (result.details != null && result.details!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  title: Text(
                    'Chi tiết câu hỏi',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  initiallyExpanded: false,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: result.details!.asMap().entries.map((entry) {
                    final detail = entry.value as Map<String, dynamic>;
                    final isCorrect = detail['selected'] == detail['correctAnswer'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : AppColors.accent2.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isCorrect ? AppColors.primary : AppColors.accent2,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Câu ${entry.key + 1}: ${detail['question']}',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bạn chọn: ${detail['selected'] ?? 'Chưa chọn'}',
                                  style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                Text(
                                  'Đáp án: ${detail['correctAnswer']}',
                                  style: GoogleFonts.nunito(
                                    color: isCorrect ? AppColors.primary : AppColors.accent2,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/quiz'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Làm lại', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppTheme.primaryButtonGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => context.go('/'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text('Về trang chủ', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
