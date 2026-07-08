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
          // ─── Hero Card (Stitch style) ─────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue, AppColors.blueContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative icon
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.psychology_outlined,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'LUYỆN TẬP HÀNG NGÀY',
                        style: GoogleFonts.workSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Thử Thách Quiz',
                      style: GoogleFonts.workSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kiểm tra kiến thức với các bài tập trắc nghiệm đa dạng theo chủ đề.',
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── Bento: Config + AI ────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main config panel
                    Expanded(
                      flex: 6,
                      child: _buildConfigPanel(quiz),
                    ),
                    const SizedBox(width: 16),
                    // AI side panel
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildAICard(quiz),
                          const SizedBox(height: 16),
                          _buildStreakCard(quiz),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildConfigPanel(quiz),
                  const SizedBox(height: 16),
                  _buildAICard(quiz),
                  const SizedBox(height: 16),
                  _buildStreakCard(quiz),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ─── Recent activity ───────────────────────
          _buildRecentActivity(),

          // ─── Error ────────────────────────────────
          if (quiz.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quiz.errorMessage!,
                      style: GoogleFonts.workSans(
                        fontSize: 13,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Config Panel ──────────────────────────────────
  Widget _buildConfigPanel(QuizProvider quiz) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skill type
          Text(
            'Chọn kỹ năng',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skillTypes.map((st) {
              final selected = _selectedSkillType == st.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedSkillType = st.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.blueBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.blue
                          : AppColors.outlineVariant,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(st.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        st.label,
                        style: GoogleFonts.workSans(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? AppColors.blue : AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Topic selection
          Text(
            'Chọn chủ đề',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openTopicSheet,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
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
                  Icon(Icons.keyboard_arrow_down,
                      color: AppColors.inkSoft, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Question count
          Text(
            'Số câu hỏi',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCountChip('5', _questionCount == 5, () {
                setState(() => _questionCount = 5);
              }),
              const SizedBox(width: 8),
              _buildCountChip('10', _questionCount == 10, () {
                setState(() => _questionCount = 10);
              }),
              const SizedBox(width: 8),
              _buildCountChip('15', _questionCount == 15, () {
                setState(() => _questionCount = 15);
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
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
              label: Text(quiz.isLoading ? 'Đang tạo đề...' : 'Bắt đầu Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.workSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.blue
                  : AppColors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.workSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
              Text(
                'câu hỏi',
                style: GoogleFonts.workSans(
                  fontSize: 11,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.80)
                      : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AI Card (Stitch purple gradient) ────────────
  Widget _buildAICard(QuizProvider quiz) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quiz Bằng AI',
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Tạo bài kiểm tra cá nhân hóa từ AI dựa trên lịch sử học của bạn.',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _startAIQuiz(quiz),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Tạo Ngay',
                          style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Streak card ──────────────────────────────────
  Widget _buildStreakCard(QuizProvider quiz) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.blueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: AppColors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chuỗi Quiz',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '0',
                    style: GoogleFonts.workSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'ngày',
                      style: GoogleFonts.workSans(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Recent activity ──────────────────────────────
  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hoạt động gần đây',
              style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/quiz/history'),
              child: Text(
                'Xem tất cả →',
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceContainerHighest),
          ),
          child: Column(
            children: [
              _RecentQuizItem(
                icon: Icons.spellcheck,
                iconBg: AppColors.blueBg,
                iconColor: AppColors.blue,
                title: 'Từ vựng cơ bản',
                subtitle: 'Hôm qua • 10 câu',
                score: '8/10',
                scoreColor: AppColors.success,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _RecentQuizItem(
                icon: Icons.hearing,
                iconBg: AppColors.warningBg,
                iconColor: AppColors.tertiary,
                title: 'Nghe hiểu TOEIC',
                subtitle: '3 ngày trước • 5 câu',
                score: '4/5',
                scoreColor: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => context.go('/quiz/history'),
          icon: const Icon(Icons.history, size: 18),
          label: const Text('Xem lịch sử quiz'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────

class _SkillTypeData {
  final String key;
  final String emoji;
  final String label;
  const _SkillTypeData(this.key, this.emoji, this.label);
}

class _RecentQuizItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle, score;
  final Color scoreColor;

  const _RecentQuizItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }
}
