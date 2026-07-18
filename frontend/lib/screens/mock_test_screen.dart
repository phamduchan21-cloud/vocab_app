import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/mini_test_questions.dart';
import '../models/mock_test.dart';
import '../providers/mock_test_provider.dart';
import '../services/mock_test_draft_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

class MockTestScreen extends StatefulWidget {
  const MockTestScreen({super.key});

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  String _purpose = 'general';
  int _questionCount = 10;
  int _durationMinutes = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<MockTestProvider>();
      prov.loadAvailableTopics();
      prov.loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MockTestProvider>();
    final draft = MockTestDraftService.load();
    final pageWidth = MediaQuery.sizeOf(context).width;
    final pagePadding = ((pageWidth - 980) / 2).clamp(20.0, 64.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
      appBar: AppBar(
        title: Text(
          'Mini-test',
          style: GoogleFonts.nunito(
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(pagePadding, 24, pagePadding, 60),
        children: [
          _buildAirmailHero(),
          if (draft != null) ...[
            const SizedBox(height: 12),
            _buildDraftBanner(draft),
          ],
          const SizedBox(height: 12),
          _buildPersonalization(prov),
          const SizedBox(height: 22),
          _sectionTitle(
            '1. Mục đích bài test',
            'Chọn cách hệ thống ưu tiên câu hỏi',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _purposeCard(
                    width,
                    'general',
                    Icons.shuffle_rounded,
                    'Tổng hợp',
                    'Trộn toàn bộ ngân hàng từ',
                  ),
                  _purposeCard(
                    width,
                    'topic',
                    Icons.local_offer_outlined,
                    'Theo chủ đề',
                    'Bám sát unit bạn đã học',
                  ),
                  _purposeCard(
                    width,
                    'weak',
                    Icons.healing_rounded,
                    'Ôn từ yếu',
                    'Ưu tiên từ hay sai và sắp quên',
                  ),
                ],
              );
            },
          ),
          if (_purpose == 'topic' && prov.availableTopics.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: prov.availableTopics.map((topic) {
                final display = MiniTestBank.displayName(topic) ?? topic;
                return _buildTopicChip(
                  display,
                  prov.selectedTopic == topic,
                  () => prov.setTopic(topic),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          _sectionTitle(
            '2. Độ khó',
            'Điều chỉnh độ sâu của ngữ cảnh và ngữ pháp',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _levelSegment(prov, 'beginner', 'Dễ', 'A1–A2'),
              const SizedBox(width: 8),
              _levelSegment(prov, 'intermediate', 'Trung bình', 'B1–B2'),
              const SizedBox(width: 8),
              _levelSegment(prov, 'advanced', 'Khó', 'B2–C1'),
            ],
          ),
          const SizedBox(height: 24),
          _sectionTitle(
            '3. Độ dài bài test',
            'Chọn số câu hoặc một gói thời gian',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              5,
              10,
              15,
              20,
            ].map((count) => _countChip(count)).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _timePreset(
                  icon: Icons.bolt_rounded,
                  title: 'Test nhanh',
                  subtitle: '2 phút · 5 câu',
                  selected: _durationMinutes == 2,
                  onTap: () => setState(() {
                    _durationMinutes = 2;
                    _questionCount = 5;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _timePreset(
                  icon: Icons.local_post_office_outlined,
                  title: 'Test đầy đủ',
                  subtitle: '10 phút · 20 câu',
                  selected: _durationMinutes == 10 && _questionCount == 20,
                  onTap: () => setState(() {
                    _durationMinutes = 10;
                    _questionCount = 20;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.10)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.rose),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đề sẽ trộn: chọn đáp án, điền từ, nghe hiểu, ghép nghĩa và sắp xếp câu.',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _startTest(context, prov),
            icon: const Icon(Icons.send_rounded),
            label: Text('Bắt đầu $_questionCount câu · $_durationMinutes phút'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 17),
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 36),

          // ── History section ───────────────────────────────

          // Progress chart (show only if 2+ history entries)
          if (prov.history.length >= 2) ...[
            _MockTestProgressChart(history: prov.history),
            const SizedBox(height: 22),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppColors.rose,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Lịch sử kiểm tra',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${prov.history.length} bài',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  if (prov.history.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.go('/mock-test/history'),
                      child: Text(
                        'Xem tất cả',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.rose,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (prov.isLoading && prov.history.isEmpty)
            const SkeletonLoading(type: SkeletonType.list, count: 3)
          else if (prov.errorMessage != null && prov.history.isEmpty)
            ErrorStateWidget(
              message: prov.errorMessage!,
              onRetry: () => prov.loadHistory(),
            )
          else if (prov.history.isEmpty)
            const EmptyStateWidget(
              title: 'Chưa có bài kiểm tra nào',
              subtitle: 'Làm một bài kiểm tra để xem kết quả tại đây.',
              showCat: false,
            )
          else
            ...prov.history.take(10).map((item) => _buildHistoryItem(item)),
        ],
      ),
    );
  }

  Widget _buildAirmailHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AIRMAIL MINI TEST',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đóng dấu tiến bộ\ncủa bạn',
                  style: GoogleFonts.nunito(
                    fontSize: 27,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Một đề ngắn, nhiều dạng câu hỏi, tập trung đúng phần bạn cần ôn.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 92,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.rose, width: 3),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_post_office_rounded,
                    color: AppColors.rose,
                    size: 34,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'MINI\nTEST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalization(MockTestProvider prov) {
    final streak = _miniTestStreak(prov.history);
    final hasHistory = prov.history.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak Mini Test: $streak ngày',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  hasHistory
                      ? 'Gợi ý hôm nay: chọn “Ôn từ yếu” để kéo lại các từ sắp quên.'
                      : 'Làm bài đầu tiên để hệ thống bắt đầu cá nhân hóa lịch ôn.',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
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

  Widget _buildDraftBanner(Map<String, dynamic> draft) {
    final answered = (draft['answers'] as List? ?? const [])
        .where((answer) => answer != null)
        .length;
    final total = draft['question_count'] as int? ?? 0;
    final remaining = draft['seconds_remaining'] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.30)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.drafts_rounded, color: AppColors.success),
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bài test đang làm dở',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '$answered/$total câu · còn ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              MockTestDraftService.clear();
              setState(() {});
            },
            child: const Text('Bỏ'),
          ),
          ElevatedButton(
            onPressed: () => _continueDraft(draft),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  void _continueDraft(Map<String, dynamic> draft) {
    final level = draft['level'] as String? ?? 'beginner';
    final purpose = draft['purpose'] as String? ?? 'general';
    final topic = draft['topic'] as String?;
    final count = draft['question_count'] as int? ?? 10;
    final duration = draft['duration_minutes'] as int? ?? 10;
    final queryParameters = <String, String>{
      'purpose': purpose,
      'count': '$count',
      'duration': '$duration',
    };
    if (topic != null) queryParameters['topic'] = topic;
    final uri = Uri(
      path: '/mock-test/play/$level',
      queryParameters: queryParameters,
    );
    context.go(uri.toString());
  }

  int _miniTestStreak(List<MockTestHistoryItem> history) {
    final days = history
        .where((item) => item.completedAt != null)
        .map((item) => DateUtils.dateOnly(item.completedAt!))
        .toSet();
    if (days.isEmpty) return 0;
    var cursor = DateUtils.dateOnly(DateTime.now());
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
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

  Widget _purposeCard(
    double width,
    String key,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = _purpose == key;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => setState(() => _purpose = key),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.rose.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.rose
                  : AppColors.ink.withValues(alpha: 0.12),
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.rose : AppColors.inkSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, size: 18, color: AppColors.rose),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelSegment(
    MockTestProvider prov,
    String key,
    String label,
    String band,
  ) {
    final selected = prov.selectedLevel == key;
    return Expanded(
      child: InkWell(
        onTap: () => prov.setLevel(key),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.ink
                  : AppColors.ink.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
              Text(
                band,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  color: selected ? Colors.white70 : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countChip(int count) {
    final selected = _questionCount == count && _durationMinutes != 2;
    return ChoiceChip(
      label: Text('$count câu'),
      selected: selected,
      onSelected: (_) => setState(() {
        _questionCount = count;
        _durationMinutes = count <= 5 ? 5 : 10;
      }),
      selectedColor: AppColors.rose,
      labelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.ink,
      ),
    );
  }

  Widget _timePreset({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.warning.withValues(alpha: 0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? AppColors.warning
                : AppColors.ink.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.warning : AppColors.inkSoft),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTest(BuildContext context, MockTestProvider prov) {
    final topic = _purpose == 'topic' ? prov.selectedTopic : null;
    final queryParameters = <String, String>{
      'purpose': _purpose,
      'count': '$_questionCount',
      'duration': '$_durationMinutes',
    };
    if (topic != null) queryParameters['topic'] = topic;
    final uri = Uri(
      path: '/mock-test/play/${prov.selectedLevel}',
      queryParameters: queryParameters,
    );
    context.go(uri.toString());
  }

  Widget _buildTopicChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label == 'Tất cả' ? label : label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.rose,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected
            ? AppColors.rose
            : AppColors.ink.withValues(alpha: 0.12),
      ),
      labelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: selected ? Colors.white : AppColors.inkSoft,
      ),
    );
  }

  Widget _buildHistoryItem(MockTestHistoryItem item) {
    final gradeColor = item.grade == 'A'
        ? AppColors.success
        : item.grade == 'B'
        ? AppColors.rose
        : item.grade == 'C'
        ? AppColors.warning
        : AppColors.danger;
    final levelLabel = item.testLevel == 'beginner'
        ? 'Cơ bản'
        : item.testLevel == 'intermediate'
        ? 'Trung cấp'
        : 'Nâng cao';
    final dateStr = item.completedAt != null
        ? '${item.completedAt!.day}/${item.completedAt!.month}/${item.completedAt!.year} ${item.completedAt!.hour}:${item.completedAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gradeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: item.scorePercent / 100,
                  strokeWidth: 3,
                  backgroundColor: AppColors.surfaceSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                ),
                Center(
                  child: Text(
                    '${item.scorePercent.round()}%',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: gradeColor,
                    ),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        levelLabel.toUpperCase(),
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: gradeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Hạng ${item.grade}',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: gradeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.correctAnswers}/${item.totalQuestions} câu đúng',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          // Retry button
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: () => context.go('/mock-test/play/${item.testLevel}'),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: AppColors.rose,
              tooltip: 'Làm lại',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple progress chart showing score trend over last mock tests.
class _MockTestProgressChart extends StatelessWidget {
  final List<MockTestHistoryItem> history;

  const _MockTestProgressChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final display = history.take(10).toList()
      ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
    if (display.length < 2) return const SizedBox.shrink();

    final maxScore = display.fold<double>(
      0,
      (max, item) => item.scorePercent > max ? item.scorePercent : max,
    );
    final chartMax = (maxScore > 20 ? maxScore : 100).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Xu hướng điểm số',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: Size.infinite,
              painter: _ScoreChartPainter(
                scores: display.map((e) => e.scorePercent).toList(),
                maxY: chartMax,
                color: AppColors.rose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  final List<double> scores;
  final double maxY;
  final Color color;

  _ScoreChartPainter({
    required this.scores,
    required this.maxY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (scores.length - 1);

    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      final y = size.height - (scores[i] / maxY * size.height * 0.85) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo((scores.length - 1) * stepX, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      final y = size.height - (scores[i] / maxY * size.height * 0.85) - 4;
      canvas.drawCircle(Offset(x, y), 3.5, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreChartPainter old) =>
      old.scores != scores || old.maxY != maxY;
}
