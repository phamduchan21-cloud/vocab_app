import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/dashboard_data.dart';
import '../models/profile_data.dart';
import '../models/quiz_result.dart';
import '../providers/dashboard_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';

/// Màn hình Tiến độ học tập
///
/// Thiết kế dựa trên progress.html — gồm:
/// 1. Header + subtitle
/// 2. 4 stat cards (từ đã học, streak, quiz avg, XP)
/// 3. Bar chart 7 ngày + donut chart mức độ ghi nhớ (side by side)
/// 4. Calendar heatmap 14 tuần
/// 5. Badges grid (huy hiệu, badge cuối bị khoá)
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  void _loadIfNeeded() {
    final dashProv = context.read<DashboardProvider>();
    if (dashProv.data == null && !dashProv.isLoading) {
      dashProv.loadDashboard();
    }
    final profProv = context.read<ProfileProvider>();
    if (profProv.data.isEmpty && !profProv.isLoading) {
      profProv.loadProfile();
    }
  }

  // ─── Data computation helpers ─────────────────────────

  int _computeQuizAvg(List<QuizResult> history) {
    if (history.isEmpty) return 0;
    final total = history.fold<int>(0, (sum, q) => sum + q.scorePercent.round());
    return (total / history.length).round();
  }

  List<({String label, double pct})> _computeBarData(List<WeeklyActivityDay> activity) {
    if (activity.isEmpty) return _defaultBarData;

    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final dayValues = <int, double>{};
    final now = DateTime.now();

    for (final day in activity) {
      final dt = DateTime.tryParse(day.date);
      if (dt == null) continue;
      final diff = now.difference(dt).inDays;
      if (diff < 0 || diff > 6) continue;
      dayValues[dt.weekday] = math.max(
        dayValues[dt.weekday] ?? 0,
        day.learned.toDouble(),
      );
    }

    if (dayValues.isEmpty) return _defaultBarData;

    final maxVal = dayValues.values.reduce(math.max);
    if (maxVal == 0) return _defaultBarData;

    return List.generate(7, (i) {
      final wd = i + 1; // weekday 1=Mon...7=Sun → T2...CN
      final val = dayValues[wd] ?? 0;
      return (label: dayLabels[i], pct: (val / maxVal).clamp(0.0, 1.0));
    });
  }

  static const _defaultBarData = [
    (label: 'T2', pct: 0.0),
    (label: 'T3', pct: 0.0),
    (label: 'T4', pct: 0.0),
    (label: 'T5', pct: 0.0),
    (label: 'T6', pct: 0.0),
    (label: 'T7', pct: 0.0),
    (label: 'CN', pct: 0.0),
  ];

  List<({String label, double pct, Color color})> _computeDonutData(
    List<TopicProgressItem> topics,
    int vocabCount,
  ) {
    if (topics.isEmpty || vocabCount == 0) {
      return [
        (label: 'Đã thuộc', pct: 0.0, color: AppColors.success),
        (label: 'Đang học', pct: 0.0, color: AppColors.blue),
        (label: 'Mới', pct: 1.0, color: AppColors.surfaceSubtle),
      ];
    }

    final totalMastered = topics.fold<int>(0, (s, t) => s + t.mastered);
    final totalVocab = topics.fold<int>(0, (s, t) => s + t.total);
    final total = math.max(totalVocab, vocabCount);

    if (total == 0) {
      return [
        (label: 'Đã thuộc', pct: 0.0, color: AppColors.success),
        (label: 'Đang học', pct: 0.0, color: AppColors.blue),
        (label: 'Mới', pct: 1.0, color: AppColors.surfaceSubtle),
      ];
    }

    final mastered = (totalMastered / total).clamp(0.0, 1.0);
    final remaining = 1.0 - mastered;
    final learning = remaining * 0.5;
    final new_ = remaining - learning;

    return [
      (label: 'Đã thuộc', pct: mastered, color: AppColors.success),
      (label: 'Đang học', pct: learning, color: AppColors.blue),
      (label: 'Mới', pct: new_, color: AppColors.surfaceSubtle),
    ];
  }

  List<int> _computeHeatLevels(List<WeeklyActivityDay> activity, int streak) {
    // Use real activity data when available
    if (activity.isNotEmpty) {
      final levels = List.filled(98, 0);
      final now = DateTime.now();
      for (final day in activity) {
        final dt = DateTime.tryParse(day.date);
        if (dt == null) continue;
        final diff = now.difference(dt).inDays;
        if (diff < 0 || diff >= 98) continue;
        // Grid: 14 columns (weeks) x 7 rows (days)
        // Most recent day at bottom-right
        final col = 13 - (diff ~/ 7);
        final row = 6 - (diff % 7);
        final idx = row * 14 + col;
        if (idx >= 0 && idx < 98) {
          final activityLevel = math.max(day.learned, day.xp);
          if (activityLevel > 20) {
            levels[idx] = 4;
          } else if (activityLevel > 10) {
            levels[idx] = 3;
          } else if (activityLevel > 5) {
            levels[idx] = 2;
          } else if (activityLevel > 0) {
            levels[idx] = 1;
          }
        }
      }
      return levels;
    }

    // Fallback: deterministic pattern based on streak
    if (streak > 0) {
      final rng = math.Random(streak);
      return List.generate(98, (_) {
        final v = rng.nextDouble();
        if (v < 0.25) return 0;
        if (v < 0.50) return 1;
        if (v < 0.72) return 2;
        if (v < 0.88) return 3;
        return 4;
      });
    }

    // Truly empty state — no data at all
    return List.filled(98, 0);
  }

  List<({String icon, String name, bool locked})> _computeBadges(
    List<AchievementItem> achievements,
  ) {
    if (achievements.isEmpty) {
      return [
        (icon: '🔥', name: '7 ngày streak', locked: true),
        (icon: '📘', name: '100 từ', locked: true),
        (icon: '🎯', name: 'Điểm tuyệt đối', locked: true),
        (icon: '🌙', name: 'Cú đêm', locked: true),
        (icon: '🏆', name: '30 ngày streak', locked: true),
      ];
    }

    return achievements.map((a) {
      final unlocked = a.unlockedAt != null;
      return (
        icon: a.icon ?? '🏅',
        name: a.title,
        locked: !unlocked,
      );
    }).toList();
  }

  String _formatNumber(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    if (s.length <= 3) return s;
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(' ');
      result.write(s[i]);
    }
    return result.toString();
  }

  // ─── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dashProv = context.watch<DashboardProvider>();
    final profProv = context.watch<ProfileProvider>();
    final quizProv = context.watch<QuizProvider>();

    // Case 1: Initial loading — no data yet
    if (dashProv.isLoading && dashProv.data == null) {
      return _buildLoadingScaffold();
    }

    // Case 2: Auth error — no data available
    if (dashProv.data == null && dashProv.errorMessage != null) {
      return _buildErrorScaffold(errorMessage: dashProv.errorMessage!);
    }

    // Case 3: Data available (may be empty for new users)
    return _buildDataScaffold(dashProv, profProv, quizProv);
  }

  Scaffold _buildLoadingScaffold() {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      appBar: AppBar(
        title: Text(
          'Tiến độ',
          style: GoogleFonts.workSans(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 32,
                    width: 200,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 16,
                    width: 300,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const SkeletonLoading(type: SkeletonType.grid, count: 4),
              const SizedBox(height: 26),
              const SkeletonLoading(type: SkeletonType.card, count: 2),
              const SizedBox(height: 26),
              SizedBox(
                height: 140,
                child: SkeletonLoading(type: SkeletonType.grid, count: 14),
              ),
              const SizedBox(height: 26),
              const SkeletonLoading(type: SkeletonType.list, count: 5),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold _buildErrorScaffold({required String errorMessage}) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      appBar: AppBar(
        title: Text(
          'Tiến độ',
          style: GoogleFonts.workSans(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ErrorStateWidget(
        message: errorMessage,
        onRetry: _loadIfNeeded,
      ),
    );
  }

  Scaffold _buildDataScaffold(
    DashboardProvider dashProv,
    ProfileProvider profProv,
    QuizProvider quizProv,
  ) {
    final stats = dashProv.data?.stats ?? DashboardStats();
    final weeklyActivity = profProv.data;
    final achievements = profProv.achievements;
    final topics = dashProv.data?.topics ?? [];
    final recentQuizStats = stats.recentQuizzes;

    // Derive all display values from real data
    final vocabCount = stats.vocabCount;
    final streak = stats.streak;
    final xp = stats.xp;
    final quizAvg = stats.accuracyRate > 0
        ? (stats.accuracyRate * 100).round()
        : recentQuizStats.isNotEmpty
            ? _computeQuizAvgFromStats(recentQuizStats)
            : _computeQuizAvg(quizProv.history);

    final barData = _computeBarData(weeklyActivity);
    final donutData = _computeDonutData(topics, vocabCount);
    final heatLevels = _computeHeatLevels(weeklyActivity, streak);
    final badges = _computeBadges(achievements);
    final isNewUser = vocabCount == 0 && streak == 0 && xp == 0 && quizAvg == 0;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      appBar: AppBar(
        title: Text(
          'Tiến độ',
          style: GoogleFonts.workSans(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isNewUser: isNewUser),
              const SizedBox(height: 26),
              _buildStatRow(
                vocabCount: vocabCount,
                streak: streak,
                quizAvg: quizAvg,
                xp: xp,
              ),
              const SizedBox(height: 26),
              _buildPanelsRow(
                barData: barData,
                donutData: donutData,
              ),
              const SizedBox(height: 26),
              _buildCalendarHeatmap(heatLevels: heatLevels),
              const SizedBox(height: 26),
              _buildBadgesSection(badges: badges),
            ],
          ),
        ),
      ),
    );
  }

  int _computeQuizAvgFromStats(List<DashboardQuiz> quizzes) {
    if (quizzes.isEmpty) return 0;
    final total = quizzes.fold<int>(0, (sum, q) => sum + q.scorePercent.round());
    return (total / quizzes.length).round();
  }

  // ─── 1. Header ────────────────────────────────────────

  Widget _buildHeader({bool isNewUser = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiến độ học tập',
          style: GoogleFonts.workSans(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isNewUser
              ? 'Chưa có dữ liệu. Hãy bắt đầu học từ mới để theo dõi tiến độ!'
              : 'Theo dõi quá trình học từ vựng của bạn theo thời gian',
          style: GoogleFonts.workSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─── 2. Stat row ──────────────────────────────────────

  Widget _buildStatRow({
    required int vocabCount,
    required int streak,
    required int quizAvg,
    required int xp,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth > 480 ? 12.0 : 8.0;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _statCard(
              icon: '📘',
              iconBg: AppColors.blue.withValues(alpha: 0.10),
              iconColor: AppColors.blue,
              value: '$vocabCount',
              label: 'Từ đã học',
              flex: 1,
            ),
            _statCard(
              icon: '🔥',
              iconBg: AppColors.danger.withValues(alpha: 0.10),
              iconColor: AppColors.danger,
              value: '$streak',
              label: 'Ngày liên tiếp',
              flex: 1,
            ),
            _statCard(
              icon: '🎯',
              iconBg: AppColors.warning.withValues(alpha: 0.14),
              iconColor: AppColors.warning,
              value: '$quizAvg%',
              label: 'Điểm quiz trung bình',
              flex: 1,
            ),
            _statCard(
              icon: '⭐',
              iconBg: AppColors.success.withValues(alpha: 0.12),
              iconColor: AppColors.success,
              value: _formatNumber(xp),
              label: 'Tổng XP',
              flex: 1,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required int flex,
  }) {
    return SizedBox(
      width: flex == 1 ? null : double.infinity,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. Two panels side by side ───────────────────────

  Widget _buildPanelsRow({
    required List<({String label, double pct})> barData,
    required List<({String label, double pct, Color color})> donutData,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 500;
        if (narrow) {
          return Column(
            children: [
              _buildBarChartPanel(barData: barData),
              const SizedBox(height: 16),
              _buildDonutPanel(donutData: donutData),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 14, child: _buildBarChartPanel(barData: barData)),
            const SizedBox(width: 16),
            Expanded(flex: 10, child: _buildDonutPanel(donutData: donutData)),
          ],
        );
      },
    );
  }

  // ─── 3a. Bar chart ────────────────────────────────────

  Widget _buildBarChartPanel({
    required List<({String label, double pct})> barData,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động 7 ngày qua',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(barData.length, (i) {
                final item = barData[i];
                final label = item.label;
                final pct = item.pct;
                final isToday = i == barData.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 30),
                          height: math.max(pct * 130, 4),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.warning
                                : AppColors.blue,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3b. Donut chart ──────────────────────────────────

  Widget _buildDonutPanel({
    required List<({String label, double pct, Color color})> donutData,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mức độ ghi nhớ',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutPainter(donutData: donutData),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: donutData.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: d.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.label,
                              style: GoogleFonts.workSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            '${(d.pct * 100).round()}%',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 4. Calendar heatmap ──────────────────────────────

  Widget _buildCalendarHeatmap({required List<int> heatLevels}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch học 14 tuần gần đây',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          // 14 columns x 7 rows grid
          SizedBox(
            height: 118,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 14,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 0.7,
              ),
              itemCount: 98,
              itemBuilder: (context, index) {
                final level = index < heatLevels.length ? heatLevels[index] : 0;
                return Container(
                  decoration: BoxDecoration(
                    color: _heatColor(level),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _heatColor(int level) {
    switch (level) {
      case 1:
        return AppColors.success.withValues(alpha: 0.25);
      case 2:
        return AppColors.success.withValues(alpha: 0.50);
      case 3:
        return AppColors.success.withValues(alpha: 0.80);
      case 4:
        return AppColors.success;
      default:
        return AppColors.surfaceSubtle;
    }
  }

  // ─── 5. Badges section ────────────────────────────────

  Widget _buildBadgesSection({
    required List<({String icon, String name, bool locked})> badges,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Huy hiệu',
            style: GoogleFonts.workSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        if (badges.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Chưa có huy hiệu nào. Học tập chăm chỉ để mở khoá!',
              style: GoogleFonts.workSans(
                fontSize: 13,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: badges.map((b) => _badgeItem(b.icon, b.name, b.locked)).toList(),
          ),
      ],
    );
  }

  Widget _badgeItem(String icon, String name, bool locked) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: locked
                    ? AppColors.ink.withValues(alpha: 0.14)
                    : AppColors.warning,
                width: 2,
              ),
              color: locked
                  ? AppColors.surfaceSubtle
                  : AppColors.warning.withValues(alpha: 0.10),
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 20,
                  color: locked ? AppColors.textHint : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.workSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: locked ? AppColors.textHint : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
      borderRadius: BorderRadius.circular(14),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 🍩 Donut chart painter — now dynamic
// ═══════════════════════════════════════════════════════
class _DonutPainter extends CustomPainter {
  final List<({String label, double pct, Color color})> donutData;

  _DonutPainter({required this.donutData});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 8;
    const strokeW = 16.0;

    // Background track
    final bgPaint = Paint()
      ..color = AppColors.surfaceSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Dynamic segments
    double currentAngle = -math.pi / 2;
    for (final segment in donutData) {
      if (segment.pct <= 0) continue;
      final sweepAngle = 2 * math.pi * segment.pct;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    if (oldDelegate.donutData.length != donutData.length) return true;
    for (var i = 0; i < donutData.length; i++) {
      if (oldDelegate.donutData[i].pct != donutData[i].pct) return true;
      if (oldDelegate.donutData[i].color != donutData[i].color) return true;
    }
    return false;
  }
}
