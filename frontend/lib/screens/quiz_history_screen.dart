import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/quiz_provider.dart';
import '../models/quiz_result.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/app_drawer.dart';

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
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử làm bài'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
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

    // Tính tổng kết
    double avgScore = 0;
    if (quiz.history.isNotEmpty) {
      avgScore = quiz.history.fold(0.0, (sum, item) => sum + item.scorePercent) / quiz.history.length;
    }

    return RefreshIndicator(
      onRefresh: () => quiz.fetchHistory(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem('${quiz.history.length}', 'Bài đã làm'),
                _summaryItem('${avgScore.toStringAsFixed(0)}%', 'Điểm TB'),
                _summaryItem(
                  '${quiz.history.fold(0, (sum, item) => sum + item.correctAnswers)}/${quiz.history.fold(0, (sum, item) => sum + item.totalQuestions)}',
                  'Đúng/Tổng',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // List
          ...quiz.history.map((item) => _buildHistoryItem(item)),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(QuizResult item) {
    final color = item.scorePercent >= 80
        ? AppColors.primary
        : item.scorePercent >= 50
            ? AppColors.accent1
            : AppColors.accent2;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(context, item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Score circle mini
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: item.scorePercent / 100,
                      strokeWidth: 4,
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Text(
                      '${item.scorePercent.toStringAsFixed(0)}%',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
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
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.correctAnswers}/${item.totalQuestions} câu đúng',
                      style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    Text(
                      _formatDate(item.completedAt),
                      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Chi tiết bài làm',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Loại:', item.quizType),
              const SizedBox(height: 6),
              _detailRow('Ngày:', _formatDate(item.completedAt)),
              const SizedBox(height: 6),
              _detailRow('Điểm:', '${item.correctAnswers}/${item.totalQuestions} (${item.scorePercent.toStringAsFixed(0)}%)'),
              if (item.details != null && item.details!.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),
                ...item.details!.asMap().entries.map((entry) {
                  final detail = entry.value as Map<String, dynamic>;
                  final isCorrect = detail['selected'] == detail['correctAnswer'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : AppColors.accent2.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 18,
                          color: isCorrect ? AppColors.primary : AppColors.accent2,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Câu ${entry.key + 1}: ${isCorrect ? 'Đúng' : 'Sai'}',
                          style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 14),
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
            child: Text('Đóng', style: GoogleFonts.nunito(color: AppColors.primary)),
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
          child: Text(label, style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 14)),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 14)),
        ),
      ],
    );
  }
}
