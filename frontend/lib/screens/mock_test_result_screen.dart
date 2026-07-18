import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/mock_test.dart';
import '../providers/mock_test_provider.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/postmark_score.dart';

class MockTestResultScreen extends StatefulWidget {
  final MockTestResult result;

  const MockTestResultScreen({super.key, required this.result});

  @override
  State<MockTestResultScreen> createState() => _MockTestResultScreenState();
}

class _MockTestResultScreenState extends State<MockTestResultScreen> {
  final Set<int> _bookmarked = {};

  MockTestResult get result => widget.result;

  @override
  Widget build(BuildContext context) {
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pagePadding = ((pageWidth - 900) / 2).clamp(16.0, 56.0);
    final scoreColor = result.scorePercent >= 80
        ? AppColors.success
        : result.scorePercent >= 60
        ? AppColors.warning
        : AppColors.danger;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Bưu kiện kết quả',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          onPressed: () => context.go('/mock-test'),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pagePadding, 24, pagePadding, 56),
        children: [
          _buildResultHero(scoreColor),
          const SizedBox(height: 16),
          _buildStats(),
          if (result.badge != null) ...[
            const SizedBox(height: 16),
            _buildBadge(),
          ],
          const SizedBox(height: 24),
          _sectionTitle(
            'Bản đồ kỹ năng',
            'Biết chính xác phần nào cần ôn thêm',
          ),
          const SizedBox(height: 12),
          _buildBreakdown(),
          const SizedBox(height: 16),
          _buildComparison(),
          const SizedBox(height: 24),
          _sectionTitle(
            'Review từng câu',
            'Đáp án, giải thích và từ cần lưu lại',
          ),
          const SizedBox(height: 12),
          ...List.generate(result.details.length, _buildReviewCard),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/mock-test'),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Làm bài khác'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/flashcard'),
                  icon: const Icon(Icons.style_rounded),
                  label: const Text('Ôn bằng Flashcard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultHero(Color color) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = [
            PostmarkScore(
              score: result.scorePercent.round(),
              label: 'ĐIỂM',
              color: color,
            ),
            const SizedBox(width: 22, height: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.scorePercent >= 90
                        ? 'Xuất sắc, thư đã đến đích!'
                        : result.scorePercent >= 70
                        ? 'Một chuyến thư rất tốt'
                        : 'Đã có lộ trình ôn tập mới',
                    style: GoogleFonts.nunito(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${result.correctAnswers}/${result.totalQuestions} câu đúng · +${result.xpEarned} XP',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _resultMessage(),
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ];
          return constraints.maxWidth < 560
              ? Column(
                  children: [
                    content[0],
                    const SizedBox(height: 12),
                    content[2],
                  ],
                )
              : Row(children: content);
        },
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _stat(Icons.check_circle_outline, '${result.correctAnswers}', 'Đúng'),
        const SizedBox(width: 8),
        _stat(
          Icons.cancel_outlined,
          '${result.totalQuestions - result.correctAnswers}',
          'Sai',
        ),
        const SizedBox(width: 8),
        _stat(
          Icons.timer_outlined,
          _formatTime(result.durationSeconds),
          'Thời gian',
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.09)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: AppColors.rose),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(fontSize: 11, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.warning,
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Huy hiệu mới',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: AppColors.inkSoft,
                ),
              ),
              Text(
                result.badge!,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown() {
    if (result.breakdown.isEmpty) {
      return const _EmptyBreakdown();
    }
    return Column(
      children: result.breakdown.entries.map((entry) {
        final stats = entry.value as Map<String, dynamic>;
        final percent = (stats['percent'] as num? ?? 0).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _skillLabel(entry.key),
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${stats['correct']}/${stats['total']} · ${percent.round()}%',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceSubtle,
                  color: percent >= 70 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComparison() {
    final history = context.watch<MockTestProvider>().history;
    final previous = history.where((item) {
      return item.testLevel == result.testLevel &&
          (result.topic == null || item.topic == result.topic);
    }).firstOrNull;
    final difference = previous == null
        ? null
        : result.scorePercent - previous.scorePercent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Icon(
            difference == null || difference >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: difference == null || difference >= 0
                ? AppColors.success
                : AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              difference == null
                  ? 'Đây là mốc đầu tiên cho cấu hình bài test này.'
                  : difference >= 0
                  ? 'Bạn tăng ${difference.toStringAsFixed(0)} điểm % so với lần gần nhất.'
                  : 'Bạn giảm ${difference.abs().toStringAsFixed(0)} điểm %. Hãy ôn lại các câu đã đánh dấu.',
              style: GoogleFonts.nunito(fontSize: 13, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(int index) {
    final detail = result.details[index] as Map<String, dynamic>;
    final isCorrect = detail['is_correct'] == true;
    final selected = detail['selected']?.toString() ?? '';
    final correct =
        detail['correct_answer']?.toString() ??
        detail['correctAnswer']?.toString() ??
        '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isCorrect ? AppColors.success : AppColors.danger).withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: (isCorrect ? AppColors.success : AppColors.danger)
              .withValues(alpha: 0.12),
          child: Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            color: isCorrect ? AppColors.success : AppColors.danger,
          ),
        ),
        title: Text(
          'Câu ${index + 1}: ${detail['question'] ?? ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        subtitle: Text(
          isCorrect ? 'Chính xác' : 'Cần ôn lại',
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: isCorrect ? AppColors.success : AppColors.danger,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _answerLine(
            'Bạn chọn',
            selected.isEmpty ? 'Chưa trả lời' : selected,
            isCorrect ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(height: 7),
          _answerLine('Đáp án đúng', correct, AppColors.success),
          if ((detail['explanation']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              detail['explanation'],
              style: GoogleFonts.nunito(
                fontSize: 13,
                height: 1.4,
                color: AppColors.inkSoft,
              ),
            ),
          ],
          if (!isCorrect) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _bookmarked.contains(index)
                    ? null
                    : () => _bookmarkQuestion(index, detail, correct),
                icon: Icon(
                  _bookmarked.contains(index)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_add_outlined,
                ),
                label: Text(
                  _bookmarked.contains(index)
                      ? 'Đã thêm Bookmark'
                      : 'Thêm vào Bookmark',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _answerLine(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: GoogleFonts.nunito(fontSize: 12, color: AppColors.inkSoft),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _bookmarkQuestion(
    int index,
    Map<String, dynamic> detail,
    String correct,
  ) async {
    final question = detail['question']?.toString() ?? '';
    final audioText = detail['audio_text']?.toString();
    final quoted = RegExp(
      r'''["']([^"']+)["']''',
    ).firstMatch(question)?.group(1);
    final questionType = detail['question_type']?.toString();
    final word =
        audioText ?? (questionType == 'matching' ? correct : quoted) ?? correct;
    final meaning = questionType == 'matching' ? quoted ?? question : correct;
    final saved = await context.read<VocabularyProvider>().bookmarkFromTest(
      word: word,
      meaning: meaning,
      topic: result.topic ?? 'mini-test',
    );
    if (!mounted) return;
    if (saved) {
      setState(() => _bookmarked.add(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa thể thêm từ này vào Bookmark.')),
      );
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.nunito(fontSize: 12, color: AppColors.inkSoft),
        ),
      ],
    );
  }

  String _skillLabel(String key) => switch (key) {
    'meaning' => 'Nghĩa từ',
    'pronunciation' => 'Nghe và phát âm',
    'context' => 'Ngữ cảnh',
    'grammar' => 'Ngữ pháp',
    _ => 'Vốn từ',
  };

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remain = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remain';
  }

  String _resultMessage() {
    if (result.scorePercent >= 90) {
      return 'Bạn đang giữ nhịp rất tốt. Hãy thử mức khó hơn để nhận thêm XP.';
    }
    if (result.scorePercent >= 70) {
      return 'Nền tảng đã chắc. Review các câu sai sẽ giúp điểm số tăng nhanh ở lần tới.';
    }
    return 'Hệ thống đã xác định nhóm kỹ năng yếu. Hãy lưu các từ sai và ôn lại bằng Flashcard.';
  }
}

class _EmptyBreakdown extends StatelessWidget {
  const _EmptyBreakdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('Breakdown kỹ năng sẽ xuất hiện ở bài test tiếp theo.'),
    );
  }
}
