import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/quiz_provider.dart';
import '../models/quiz_result.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';

const _entryCurve = Cubic(0.34, 1.56, 0.64, 1);

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen>
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().fetchHistory();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
      backgroundColor: AppColors.luxuryBg,
      appBar: AppBar(
        backgroundColor: AppColors.luxurySurface,
        foregroundColor: AppColors.luxuryEspresso,
        scrolledUnderElevation: 0,
        title: Text(
          'Lịch sử làm bài',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppColors.luxuryEspresso,
          ),
        ),
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

    double avgScore = 0;
    if (quiz.history.isNotEmpty) {
      avgScore =
          quiz.history.fold<double>(
            0.0,
            (sum, item) => sum + item.scorePercent,
          ) /
          quiz.history.length;
    }
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pagePadding = ((pageWidth - 900) / 2).clamp(20.0, 64.0);

    return RefreshIndicator(
      onRefresh: () => quiz.fetchHistory(),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            padding: EdgeInsets.fromLTRB(pagePadding, 20, pagePadding, 60),
            children: [
              // ── Summary card (double-bezel) ────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.luxuryBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.luxurySurface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryItem('${quiz.history.length}', 'Bài đã làm'),
                      _summaryItem('${avgScore.round()}%', 'Điểm TB'),
                      _summaryItem(
                        '${quiz.history.fold(0, (sum, item) => sum + item.correctAnswers)}'
                            '/${quiz.history.fold(0, (sum, item) => sum + item.totalQuestions)}',
                        'Đúng/Tổng',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Section title ──────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Các bài đã làm',
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
              ),

              // ── History list ───────────────────────────
              ...quiz.history.map((item) => _buildHistoryItem(item)),
              if (quiz.hasMoreHistory)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.luxuryBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: AppColors.luxurySurface,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: quiz.isLoading
                              ? null
                              : () => quiz.fetchHistory(loadMore: true),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: quiz.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.luxuryBrown,
                                    ),
                                  )
                                : Text(
                                    'Xem thêm',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.luxuryBrown,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.luxuryEspresso,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 12, color: AppColors.luxuryText),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(QuizResult item) {
    final score = item.scorePercent;
    final color = score >= 80
        ? AppColors.luxuryGreen
        : score >= 50
        ? AppColors.luxuryGold
        : AppColors.luxuryDanger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.luxuryBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.luxurySurface,
          borderRadius: BorderRadius.circular(11),
        ),
        child: InkWell(
          onTap: () => _showDetailDialog(context, item),
          borderRadius: BorderRadius.circular(11),
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
                        backgroundColor: AppColors.luxuryBg,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      Text(
                        '${score.round()}%',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.luxuryEspresso,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.correctAnswers}/${item.totalQuestions} câu đúng',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.luxuryText,
                        ),
                      ),
                      Text(
                        _formatDate(item.completedAt),
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.luxuryTextHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.luxuryTextHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, QuizResult item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.luxurySurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.luxurySurface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text(
                    'Chi tiết bài làm',
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.luxuryEspresso,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('Loại:', item.quizType),
                          const SizedBox(height: 6),
                          _detailRow('Ngày:', _formatDate(item.completedAt)),
                          const SizedBox(height: 6),
                          _detailRow(
                            'Điểm:',
                            '${item.correctAnswers}/${item.totalQuestions} '
                                '(${item.scorePercent.round()}%)',
                          ),
                          if (item.details != null &&
                              item.details!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              height: 1.5,
                              color: AppColors.luxuryBorder,
                            ),
                            const SizedBox(height: 8),
                            ...item.details!.asMap().entries.map((entry) {
                              final detail =
                                  entry.value as Map<String, dynamic>;
                              final correctAnswer =
                                  detail['correct_answer'] ??
                                  detail['correctAnswer'];
                              final isCorrect =
                                  detail['selected'] == correctAnswer;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? AppColors.luxuryGreen.withValues(
                                          alpha: 0.06,
                                        )
                                      : AppColors.luxuryDanger.withValues(
                                          alpha: 0.04,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCorrect
                                        ? AppColors.luxuryGreen.withValues(
                                            alpha: 0.25,
                                          )
                                        : AppColors.luxuryDanger.withValues(
                                            alpha: 0.15,
                                          ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      size: 18,
                                      color: isCorrect
                                          ? AppColors.luxuryGreen
                                          : AppColors.luxuryDanger,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Câu ${entry.key + 1}: ${isCorrect ? 'Đúng' : 'Sai'}',
                                      style: GoogleFonts.nunito(
                                        color: AppColors.luxuryEspresso,
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.luxuryBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: AppColors.luxurySurface,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => Navigator.pop(ctx),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Đóng',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.luxuryBrown,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.luxuryBrown.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 12,
                                    color: AppColors.luxuryBrown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            style: GoogleFonts.nunito(
              color: AppColors.luxuryText,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.nunito(
              color: AppColors.luxuryEspresso,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
