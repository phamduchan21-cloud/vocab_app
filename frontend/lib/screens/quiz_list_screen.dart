import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/quiz_topic.dart';
import '../providers/quiz_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';

const _entryCurve = Cubic(0.34, 1.56, 0.64, 1);

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen>
    with SingleTickerProviderStateMixin {
  int _questionCount = 10;
  String _selectedSkillType = 'all';
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _skillTypes = [
    _SkillTypeData('all', Icons.auto_awesome, 'Kết hợp', 'Đủ 4 kỹ năng'),
    _SkillTypeData(
      'vocabulary',
      Icons.menu_book_rounded,
      'Từ vựng',
      'Từ và nghĩa',
    ),
    _SkillTypeData(
      'grammar',
      Icons.account_tree_outlined,
      'Ngữ pháp',
      'Cấu trúc câu',
    ),
    _SkillTypeData(
      'reading',
      Icons.chrome_reader_mode_outlined,
      'Đọc hiểu',
      'Đọc và suy luận',
    ),
    _SkillTypeData(
      'listening',
      Icons.headphones_rounded,
      'Nghe hiểu',
      'Giọng Anh-Mỹ',
    ),
  ];

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
      context.read<QuizProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI không khả dụng: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pagePadding = ((pageWidth - 1120) / 2).clamp(20.0, 48.0);

    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      appBar: AppBar(
        backgroundColor: AppColors.luxurySurface,
        foregroundColor: AppColors.luxuryEspresso,
        title: Text(
          'Quiz theo chủ đề',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppColors.luxuryEspresso,
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            padding: EdgeInsets.fromLTRB(pagePadding, 16, pagePadding, 32),
            children: [
              // ─── Hero Card (luxury gradient) ───────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.luxuryBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.luxuryGradient,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          Icons.psychology_outlined,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'LUYỆN TẬP HÀNG NGÀY',
                              style: GoogleFonts.nunito(
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
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kiểm tra kiến thức với các bài tập trắc nghiệm đa dạng theo chủ đề.',
                            style: GoogleFonts.nunito(
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
                        Expanded(flex: 6, child: _buildConfigPanel(quiz)),
                        const SizedBox(width: 16),
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
                    color: AppColors.luxuryDanger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.luxuryDanger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.luxuryDanger,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          quiz.errorMessage!,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppColors.luxuryDanger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Config Panel ──────────────────────────────────
  Widget _buildConfigPanel(QuizProvider quiz) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.luxuryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.luxurySurface,
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill type
            Text(
              'Chọn kỹ năng',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryEspresso,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _skillTypes.map((st) {
                final selected = _selectedSkillType == st.key;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: 'Kỹ năng ${st.label}',
                  child: SizedBox(
                    width: 148,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selectedSkillType = st.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.luxuryBrown.withValues(alpha: 0.09)
                              : AppColors.luxuryBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.luxuryBrown
                                : AppColors.luxuryBorder,
                            width: selected ? 1.8 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              st.icon,
                              size: 22,
                              color: selected
                                  ? AppColors.luxuryBrown
                                  : AppColors.luxuryText,
                            ),
                            const SizedBox(height: 9),
                            Text(
                              st.label,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.luxuryEspresso,
                              ),
                            ),
                            Text(
                              st.description,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: AppColors.luxuryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_selectedSkillType == 'listening') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.luxuryGold.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.luxuryGold.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      color: AppColors.luxuryBrown,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bạn sẽ nghe đúng đoạn hội thoại tiếng Anh bằng giọng Anh-Mỹ rõ ràng, sau đó chọn đáp án.',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.luxuryEspresso,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Container(height: 1.5, color: AppColors.luxuryBorder),
            const SizedBox(height: 20),

            // Topic selection
            Text(
              'Chọn chủ đề',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryEspresso,
              ),
            ),
            const SizedBox(height: 12),
            _buildTopicGrid(quiz),

            const SizedBox(height: 20),

            // Question count
            Text(
              'Số câu hỏi',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryEspresso,
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

            // Start button — button-in-button
            _buildLuxuryButton(
              label: quiz.isLoading ? 'Đang tạo đề...' : 'Bắt đầu Quiz',
              isLoading: quiz.isLoading,
              onPressed: quiz.isLoading ? null : () => _startQuiz(quiz),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicGrid(QuizProvider quiz) {
    final topics = <QuizTopic>[
      const QuizTopic(key: 'all', label: 'Tất cả chủ đề'),
      ...quiz.topics,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: topics.map((topic) {
            final selected = quiz.selectedTopic == topic.key;
            return SizedBox(
              width: cardWidth,
              child: Semantics(
                button: true,
                selected: selected,
                label: 'Chủ đề ${topic.label}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => quiz.setTopic(topic.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.luxuryBrown.withValues(alpha: 0.09)
                          : AppColors.luxuryBg,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: selected
                            ? AppColors.luxuryBrown
                            : AppColors.luxuryBorder,
                        width: selected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _topicColor(
                              topic.key,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _topicIcon(topic.key),
                            size: 18,
                            color: _topicColor(topic.key),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            topic.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.luxuryEspresso,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 17,
                            color: AppColors.luxuryBrown,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _topicIcon(String key) => switch (key) {
    'family' => Icons.family_restroom_rounded,
    'travel' => Icons.flight_takeoff_rounded,
    'work' => Icons.work_outline_rounded,
    'food' => Icons.restaurant_rounded,
    'health' => Icons.favorite_outline_rounded,
    'education' => Icons.school_outlined,
    'technology' => Icons.devices_rounded,
    'daily_life' => Icons.wb_sunny_outlined,
    _ => Icons.grid_view_rounded,
  };

  Color _topicColor(String key) => switch (key) {
    'health' => AppColors.luxuryDanger,
    'education' => AppColors.luxuryGreen,
    'food' => AppColors.luxuryGold,
    'technology' => AppColors.luxuryBrown,
    _ => AppColors.luxuryBrownLight,
  };

  Widget _buildCountChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label câu hỏi',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.luxuryBrown : AppColors.luxurySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.luxuryBrown
                    : AppColors.luxuryBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.luxuryEspresso,
                  ),
                ),
                Text(
                  'câu hỏi',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.80)
                        : AppColors.luxuryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryButton({
    required String label,
    bool isLoading = false,
    VoidCallback? onPressed,
    IconData? trailingIcon,
    bool fullWidth = true,
  }) {
    final child = Container(
      decoration: BoxDecoration(
        gradient: AppColors.luxuryGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                if (!isLoading) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      trailingIcon ?? Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }

  // ─── AI Card (luxury dark gradient) ────────────
  Widget _buildAICard(QuizProvider quiz) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.luxuryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.luxuryGradientDark,
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -20,
              child: Icon(
                Icons.auto_awesome,
                size: 80,
                color: Colors.white.withValues(alpha: 0.12),
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
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Tạo bài kiểm tra cá nhân hóa từ AI dựa trên lịch sử học của bạn.',
                  style: GoogleFonts.nunito(
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
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => _startAIQuiz(quiz),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Tạo Ngay',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: Colors.white,
                                ),
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
    );
  }

  // ─── Streak card ──────────────────────────────────
  Widget _buildStreakCard(QuizProvider quiz) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.luxuryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.luxuryBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.luxurySurface,
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.luxuryGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                color: AppColors.luxuryGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuỗi Quiz',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.luxuryText,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '0',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.luxuryEspresso,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'ngày',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.luxuryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryEspresso,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/quiz/history'),
              child: Text(
                'Xem tất cả →',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.luxuryBrown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
            child: Column(
              children: [
                _RecentQuizItem(
                  icon: Icons.spellcheck,
                  iconBg: AppColors.luxuryBrownLight.withValues(alpha: 0.15),
                  iconColor: AppColors.luxuryBrown,
                  title: 'Từ vựng cơ bản',
                  subtitle: 'Hôm qua • 10 câu',
                  score: '8/10',
                  scoreColor: AppColors.luxuryGreen,
                ),
                Container(
                  height: 1.5,
                  color: AppColors.luxuryBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _RecentQuizItem(
                  icon: Icons.hearing,
                  iconBg: AppColors.luxuryBrownPale.withValues(alpha: 0.2),
                  iconColor: AppColors.luxuryBrownLight,
                  title: 'Nghe hiểu TOEIC',
                  subtitle: '3 ngày trước • 5 câu',
                  score: '4/5',
                  scoreColor: AppColors.luxuryGreen,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildLuxuryButton(
          label: 'Xem lịch sử quiz',
          onPressed: () => context.go('/quiz/history'),
          trailingIcon: Icons.history,
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────

class _SkillTypeData {
  final String key;
  final IconData icon;
  final String label;
  final String description;
  const _SkillTypeData(this.key, this.icon, this.label, this.description);
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
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.luxuryText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: GoogleFonts.playfairDisplay(
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
