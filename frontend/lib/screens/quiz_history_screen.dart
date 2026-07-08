import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/quiz_provider.dart';
import '../models/quiz_result.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().fetchHistory();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Lịch sử làm bài',
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
      ),
      body: _buildBody(context, quiz),
    );
  }

  Widget _buildBody(BuildContext context, QuizProvider quiz) {
    if (quiz.isLoading && quiz.history.isEmpty) {
      return const SkeletonLoading(type: SkeletonType.list);
    }

    if (quiz.errorMessage != null && quiz.history.isEmpty) {
      return ErrorStateWidget(
        message: quiz.errorMessage!,
        onRetry: () => quiz.fetchHistory(),
      );
    }

    if (quiz.history.isEmpty) {
      return const EmptyStateWidget(
        title: 'Chưa có lịch sử làm bài',
        subtitle: 'Hãy làm một bài quiz để bắt đầu!',
        action: 'Làm bài ngay',
        showCat: true,
      );
    }

    // Stats summary
    double avgScore = 0;
    if (quiz.history.isNotEmpty) {
      avgScore = quiz.history.fold<double>(
            0.0,
            (sum, item) => sum + item.scorePercent,
          ) /
          quiz.history.length;
    }

    return RefreshIndicator(
      onRefresh: () => quiz.fetchHistory(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
        children: [
          // â”€â”€ Summary card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                _summaryItem(
                  '${quiz.history.length}',
                  'Bài đã làm',
                ),
                _summaryItem(
                  '${avgScore.round()}%',
                  'Điểm TB',
                ),
                _summaryItem(
                  '${quiz.history.fold(0, (sum, item) => sum + item.correctAnswers)}'
                  '/${quiz.history.fold(0, (sum, item) => sum + item.totalQuestions)}',
                  'Đúng/Tổng',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // â”€â”€ Section title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Các bài đã làm',
              style: GoogleFonts.workSans(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
          ),

          // â”€â”€ History list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          ...quiz.history.map((item) => _buildHistoryItem(item)),
          if (quiz.hasMoreHistory)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: TextButton(
                  onPressed: quiz.isLoading ? null : () => quiz.fetchHistory(loadMore: true),
                  child: quiz.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Xem thêm', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 12,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(QuizResult item) {
    final score = item.scorePercent;
    final color = score >= 80
        ? AppColors.success
        : score >= 50
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.ink.withValues(alpha: 0.10),
        ),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Score circle mini
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 3,
                      backgroundColor: AppColors.surfaceSubtle,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(color),
                    ),
                    Text(
                      '${score.round()}%',
                      style: GoogleFonts.ibmPlexMono(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.quizType,
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.correctAnswers}/${item.totalQuestions} câu đúng',
                      style: GoogleFonts.workSans(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    Text(
                      _formatDate(item.completedAt),
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, QuizResult item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          'Chi tiết bài làm',
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.ink,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Loáº¡i:', item.quizType),
              const SizedBox(height: 6),
              _detailRow('Ngày:', _formatDate(item.completedAt)),
              const SizedBox(height: 6),
              _detailRow(
                'Điểm:',
                '${item.correctAnswers}/${item.totalQuestions} '
                    '(${item.scorePercent.round()}%)',
              ),
              if (item.details != null && item.details!.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...item.details!.asMap().entries.map((entry) {
                    final detail = entry.value as Map<String, dynamic>;
                  final correctAnswer =
                      detail['correct_answer'] ?? detail['correctAnswer'];
                  final isCorrect = detail['selected'] == correctAnswer;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppColors.success.withValues(alpha: 0.06)
                          : AppColors.danger.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 18,
                          color: isCorrect
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Câu ${entry.key + 1}: '
                              '${isCorrect ? 'Đúng' : 'Sai'}',
                          style: GoogleFonts.workSans(
                            color: AppColors.ink,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Đóng',
              style: GoogleFonts.workSans(
                fontWeight: FontWeight.w600,
                color: AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GoogleFonts.workSans(
              color: AppColors.inkSoft,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.workSans(
              color: AppColors.ink,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
