import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/dashboard_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/flashcard_topic_sheet.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  int _questionCount = 10;
  String _selectedSkillType = 'all';

  static const _skillTypes = [
    _SkillTypeData('all', '📚', 'Tất cả'),
    _SkillTypeData('vocabulary', '📖', 'Từ vựng'),
    _SkillTypeData('grammar', '📐', 'Ngữ pháp'),
    _SkillTypeData('reading', '📝', 'Đọc hiểu'),
    _SkillTypeData('listening', '👂', 'Nghe hiểu'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().fetchCategories();
      final dashboard = context.read<DashboardProvider>();
      if (dashboard.data == null && !dashboard.isLoading) {
        dashboard.loadDashboard();
      }
    });
  }

  Future<void> _startQuiz(QuizProvider quiz) async {
    await quiz.generateQuiz(
      count: _questionCount,
      topic: quiz.selectedTopic,
      skillType: _selectedSkillType == 'all' ? null : _selectedSkillType,
    );
    if (!mounted) return;
    context.go('/quiz/play');
  }

  Future<void> _startAIQuiz(QuizProvider quiz) async {
    final aiService = AIService(context.read<ApiService>());
    try {
      final questions = await aiService.generateQuiz(
        count: _questionCount,
        topic: quiz.selectedTopic == 'all' ? null : quiz.selectedTopic,
      );
      if (!mounted) return;
      quiz.setAIQuestions(questions);
      context.go('/quiz/play');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI không khả dụng: $e')),
      );
    }
  }

  void _openTopicSheet() {
    final quiz = context.read<QuizProvider>();
    final dashboard = context.read<DashboardProvider>();
    final topics = dashboard.data?.topics.map((item) => item.topic).toList() ?? [];
    final topicItemCount = <String, int>{};
    if (dashboard.data != null) {
      for (final t in dashboard.data!.topics) {
        topicItemCount[t.topic] = t.total;
      }
    }

    FlashcardTopicSheet.show(
      context,
      topics: topics,
      topicItemCount: topicItemCount,
      selectedTopic: quiz.selectedTopic,
      onTopicChanged: (topic) => quiz.setTopic(topic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Quiz theo chủ đề',
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.ink,
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _HeroCard(
            selectedTopic: quiz.selectedTopic,
            questionCount: _questionCount,
          ),
          const SizedBox(height: 18),

          // ── Skill type filter ────────────────────────
          Text(
            'Chọn kỹ năng',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skillTypes.map((st) => _SkillChip(
              data: st,
              selected: _selectedSkillType == st.key,
              onTap: () => setState(() => _selectedSkillType = st.key),
            )).toList(),
          ),
          const SizedBox(height: 18),

          // ── Topic selection (bottom sheet) ──────────
          Text(
            'Chọn chủ đề',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _openTopicSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.ink.withValues(alpha: 0.10)),
              ),
              child: Row(
                children: [
                  const Text('📚', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    quiz.selectedTopic == 'all'
                        ? 'Tất cả chủ đề'
                        : quiz.selectedTopic,
                    style: GoogleFonts.workSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down, color: AppColors.inkSoft, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Số câu hỏi',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CountChip(
                label: '5 câu',
                selected: _questionCount == 5,
                onTap: () => setState(() => _questionCount = 5),
              ),
              const SizedBox(width: 8),
              _CountChip(
                label: '10 câu',
                selected: _questionCount == 10,
                onTap: () => setState(() => _questionCount = 10),
              ),
              const SizedBox(width: 8),
              _CountChip(
                label: '15 câu',
                selected: _questionCount == 15,
                onTap: () => setState(() => _questionCount = 15),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _ModeTile(
            icon: Icons.auto_awesome_outlined,
            title: 'Quiz nhanh',
            subtitle: 'Sinh câu hỏi từ bộ từ vựng bạn đã học theo chủ đề.',
          ),
          const SizedBox(height: 10),
          _ModeTile(
            icon: Icons.stacked_bar_chart_outlined,
            title: 'Luyện theo tiến độ',
            subtitle: 'Ưu tiên các từ đang yếu và sắp đến lịch ôn.',
          ),
          const SizedBox(height: 10),
          // AI Quiz button
          InkWell(
            onTap: () => _startAIQuiz(quiz),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🤖', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiz bằng AI',
                          style: GoogleFonts.workSans(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'AI sinh câu hỏi thông minh từ vựng | Miễn phí',
                          style: GoogleFonts.workSans(
                            fontSize: 12, color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.7), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (quiz.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                quiz.errorMessage!,
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  color: AppColors.danger,
                ),
              ),
            ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: quiz.isLoading ? null : () => _startQuiz(quiz),
            icon: quiz.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(quiz.isLoading ? 'Đang tạo đề...' : 'Bắt đầu quiz'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/quiz/history'),
            icon: const Icon(Icons.history),
            label: const Text('Xem lịch sử quiz'),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String selectedTopic;
  final int questionCount;

  const _HeroCard({
    required this.selectedTopic,
    required this.questionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tập trung vào từng chủ đề',
            style: GoogleFonts.workSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedTopic == 'all'
                ? 'Hệ thống sẽ trộn từ vựng từ tất cả chủ đề bạn đã học.'
                : 'Bạn đang luyện chủ đề "$selectedTopic" với $questionCount câu hỏi.',
            style: GoogleFonts.workSans(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.ink
                  : AppColors.ink.withValues(alpha: 0.10),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.workSans(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
    );
  }
}

class _SkillChip extends StatelessWidget {
  final _SkillTypeData data;
  final bool selected;
  final VoidCallback onTap;

  const _SkillChip({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(data.label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.blue,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.blue : AppColors.ink.withValues(alpha: 0.12),
      ),
      labelStyle: GoogleFonts.workSans(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: selected ? Colors.white : AppColors.inkSoft,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SkillTypeData {
  final String key;
  final String emoji;
  final String label;

  const _SkillTypeData(this.key, this.emoji, this.label);
}
