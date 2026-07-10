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
import '../widgets/weekly_chart.dart';

// ─── Entry animation (spring cubic) ────────────────────
class _EntryAnimation extends StatefulWidget {
  final Widget child;
  const _EntryAnimation({required this.child});

  @override
  State<_EntryAnimation> createState() => _EntryAnimationState();
}

class _EntryAnimationState extends State<_EntryAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Double-bezel card wrapper ─────────────────────────
class _DoubleBezel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const _DoubleBezel({
    required this.child,
    this.padding,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final innerPad = padding ?? const EdgeInsets.all(20);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.luxuryBorder, width: 1.2),
      ),
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius - 2),
          border: Border.all(
            color: AppColors.luxuryBorder.withValues(alpha: 0.45),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 3),
          child: Padding(padding: innerPad, child: child),
        ),
      ),
    );
  }
}

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
    if (dashProv.data == null && !dashProv.isLoading) dashProv.loadDashboard();
    final profProv = context.read<ProfileProvider>();
    if (profProv.data.isEmpty && !profProv.isLoading) profProv.loadProfile();
  }

  int _computeQuizAvg(List<QuizResult> history) {
    if (history.isEmpty) return 0;
    final total =
        history.fold<int>(0, (sum, q) => sum + q.scorePercent.round());
    return (total / history.length).round();
  }

  List<({String label, double pct})> _computeBarData(
      List<WeeklyActivityDay> activity) {
    if (activity.isEmpty) return _defaultBarData;
    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final dayValues = <int, double>{};
    final now = DateTime.now();
    for (final day in activity) {
      final dt = DateTime.tryParse(day.date);
      if (dt == null) continue;
      final diff = now.difference(dt).inDays;
      if (diff < 0 || diff > 6) continue;
      dayValues[dt.weekday] =
          math.max(dayValues[dt.weekday] ?? 0, day.learned.toDouble());
    }
    if (dayValues.isEmpty) return _defaultBarData;
    final maxVal = dayValues.values.reduce(math.max);
    if (maxVal == 0) return _defaultBarData;
    return List.generate(7, (i) {
      final wd = i + 1;
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
        (label: 'Da thuoc', pct: 0.0, color: AppColors.luxuryGreen),
        (label: 'Dang hoc', pct: 0.0, color: AppColors.luxuryBrownLight),
        (label: 'Moi', pct: 1.0, color: AppColors.luxuryBorder),
      ];
    }
    final totalMastered = topics.fold<int>(0, (s, t) => s + t.mastered);
    final totalVocab = topics.fold<int>(0, (s, t) => s + t.total);
    final total = math.max(totalVocab, vocabCount);
    if (total == 0) {
      return [
        (label: 'Da thuoc', pct: 0.0, color: AppColors.luxuryGreen),
        (label: 'Dang hoc', pct: 0.0, color: AppColors.luxuryBrownLight),
        (label: 'Moi', pct: 1.0, color: AppColors.luxuryBorder),
      ];
    }
    final mastered = (totalMastered / total).clamp(0.0, 1.0);
    final remaining = 1.0 - mastered;
    final learning = remaining * 0.5;
    final new_ = remaining - learning;
    return [
      (label: 'Da thuoc', pct: mastered, color: AppColors.luxuryGreen),
      (label: 'Dang hoc', pct: learning, color: AppColors.luxuryBrownLight),
      (label: 'Moi', pct: new_, color: AppColors.luxuryBorder),
    ];
  }

  List<int> _computeHeatLevels(List<WeeklyActivityDay> activity, int streak) {
    if (activity.isNotEmpty) {
      final levels = List.filled(98, 0);
      final now = DateTime.now();
      for (final day in activity) {
        final dt = DateTime.tryParse(day.date);
        if (dt == null) continue;
        final diff = now.difference(dt).inDays;
        if (diff < 0 || diff >= 98) continue;
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
    if (streak > 0) {
      return List.filled(98, 0);
    }
    return List.filled(98, 0);
  }

  List<({String icon, String name, bool locked})> _computeBadges(
    List<AchievementItem> achievements,
  ) {
    if (achievements.isEmpty) {
      return [
        (icon: '\u{1F525}', name: '7 ngay streak', locked: true),
        (icon: '\u{1F4D8}', name: '100 tu', locked: true),
        (icon: '\u{1F3AF}', name: 'Diem tuyet doi', locked: true),
        (icon: '\u{1F319}', name: 'Cu dem', locked: true),
        (icon: '\u{1F3C6}', name: '30 ngay streak', locked: true),
      ];
    }
    return achievements.map((a) {
      final unlocked = a.unlockedAt != null;
      return (icon: a.icon ?? '\u{1F3C5}', name: a.title, locked: !unlocked);
    }).toList();
  }

  String _formatNumber(int n) {
    if (n <= 0) return '0';
    final s = n.toString();
    if (s.length <= 3) return s;
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(' ');
      result.write(s[i]);
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    final dashProv = context.watch<DashboardProvider>();
    final profProv = context.watch<ProfileProvider>();
    final quizProv = context.watch<QuizProvider>();

    if (dashProv.isLoading && dashProv.data == null) {
      return _buildLoadingScaffold();
    }
    if (dashProv.data == null && dashProv.errorMessage != null) {
      return _buildErrorScaffold(errorMessage: dashProv.errorMessage!);
    }
    return _buildDataScaffold(dashProv, profProv, quizProv);
  }

  Scaffold _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      appBar: AppBar(
        title: Text(
          'Tien do',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.luxuryEspresso,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        color: AppColors.luxuryBg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  height: 32,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppColors.luxuryBorder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 16,
                  width: 300,
                  decoration: BoxDecoration(
                    color: AppColors.luxuryBorder,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ]),
              const SizedBox(height: 26),
              const SkeletonLoading(type: SkeletonType.grid, count: 4),
              const SizedBox(height: 26),
              const SkeletonLoading(type: SkeletonType.card, count: 2),
              const SizedBox(height: 26),
              SizedBox(
                height: 140,
                child:
                    const SkeletonLoading(type: SkeletonType.grid, count: 14),
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
      backgroundColor: AppColors.luxuryBg,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      appBar: AppBar(
        title: Text(
          'Tien do',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.luxuryEspresso,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ErrorStateWidget(message: errorMessage, onRetry: _loadIfNeeded),
    );
  }

  Scaffold _buildDataScaffold(DashboardProvider dashProv,
      ProfileProvider profProv, QuizProvider quizProv) {
    final stats = dashProv.data?.stats ?? DashboardStats();
    final weeklyActivity = profProv.data;
    final achievements = profProv.achievements;
    final topics = dashProv.data?.topics ?? [];
    final skills = dashProv.data?.skills ?? [];
    final recentQuizStats = stats.recentQuizzes;
    final vocabCount = stats.vocabCount;
    final streak = stats.streak;
    final xp = stats.xp;
    final weeklyProgress = stats.weeklyProgress;
    final quizAvg = stats.accuracyRate > 0
        ? stats.accuracyRate.round()
        : recentQuizStats.isNotEmpty
            ? _computeQuizAvgFromStats(recentQuizStats)
            : _computeQuizAvg(quizProv.history);
    final barData = _computeBarData(weeklyActivity);
    final donutData = _computeDonutData(topics, vocabCount);
    final heatLevels = _computeHeatLevels(weeklyActivity, streak);
    final badges = _computeBadges(achievements);
    final isNewUser = vocabCount == 0 && streak == 0 && xp == 0 && quizAvg == 0;

    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      appBar: AppBar(
        title: Text(
          'Tien do',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.luxuryEspresso,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        color: AppColors.luxuryBg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isNewUser: isNewUser),
              const SizedBox(height: 24),
              _buildStatRow(
                  vocabCount: vocabCount,
                  streak: streak,
                  quizAvg: quizAvg,
                  xp: xp),
              const SizedBox(height: 24),
              _buildPanelsRow(barData: barData, donutData: donutData),
              const SizedBox(height: 24),
              _buildWeeklyChartCard(weeklyActivity, xp, weeklyProgress),
              const SizedBox(height: 24),
              _buildSkillsCard(skills),
              const SizedBox(height: 24),
              _buildCalendarHeatmap(heatLevels: heatLevels),
              const SizedBox(height: 24),
              _buildBadgesSection(badges: badges),
            ],
          ),
        ),
      ),
    );
  }

  int _computeQuizAvgFromStats(List<DashboardQuiz> quizzes) {
    if (quizzes.isEmpty) return 0;
    final total =
        quizzes.fold<int>(0, (sum, q) => sum + q.scorePercent.round());
    return (total / quizzes.length).round();
  }

  Widget _buildHeader({bool isNewUser = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tien do hoc tap',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.luxuryEspresso,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isNewUser
              ? 'Chua co du lieu. Hay bat dau hoc tu moi!'
              : 'Theo doi qua trinh hoc tu vung cua ban.',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppColors.luxuryText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
      {required int vocabCount,
      required int streak,
      required int quizAvg,
      required int xp}) {
    return LayoutBuilder(builder: (context, constraints) {
      final gap = constraints.maxWidth > 480 ? 12.0 : 8.0;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        _statCard(
            icon: '\u{1F4D8}',
            iconBg:
                AppColors.luxuryBrown.withValues(alpha: 0.10),
            iconColor: AppColors.luxuryBrown,
            value: '$vocabCount',
            label: 'Tu da hoc'),
        _statCard(
            icon: '\u{1F525}',
            iconBg: AppColors.luxuryGold.withValues(alpha: 0.10),
            iconColor: AppColors.luxuryGold,
            value: '$streak',
            label: 'Ngay lien tiep'),
        _statCard(
            icon: '\u{1F3AF}',
            iconBg: AppColors.luxuryGreen.withValues(alpha: 0.10),
            iconColor: AppColors.luxuryGreen,
            value: '$quizAvg%',
            label: 'Diem quiz TB'),
        _statCard(
            icon: '\u{2B50}',
            iconBg: AppColors.luxuryBrownPale.withValues(alpha: 0.20),
            iconColor: AppColors.luxuryBrown,
            value: _formatNumber(xp),
            label: 'Tong XP'),
      ]);
    });
  }

  Widget _statCard(
      {required String icon,
      required Color iconBg,
      required Color iconColor,
      required String value,
      required String label}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width > 480 ? null : double.infinity,
      child: _DoubleBezel(
        borderRadius: 14,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.luxuryEspresso,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.luxuryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelsRow({
    required List<({String label, double pct})> barData,
    required List<({String label, double pct, Color color})> donutData,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 500;
      if (narrow) {
        return Column(children: [
          _buildBarChartPanel(barData: barData),
          const SizedBox(height: 16),
          _buildDonutPanel(donutData: donutData),
        ]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 14, child: _buildBarChartPanel(barData: barData)),
          const SizedBox(width: 16),
          Expanded(flex: 10, child: _buildDonutPanel(donutData: donutData)),
        ],
      );
    });
  }

  Widget _buildBarChartPanel(
      {required List<({String label, double pct})> barData}) {
    return _DoubleBezel(
      borderRadius: 14,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoat dong 7 ngay qua',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.luxuryEspresso,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(barData.length, (i) {
              final item = barData[i];
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
                          height: math.max(item.pct * 130, 4),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.luxuryGold
                                : AppColors.luxuryBrown,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            color: AppColors.luxuryText,
                          ),
                        ),
                      ]),
                ),
              );
            })),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutPanel(
      {required List<({String label, double pct, Color color})> donutData}) {
    return _DoubleBezel(
      borderRadius: 14,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muc do ghi nho',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.luxuryEspresso,
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            SizedBox(
              width: 110,
              height: 110,
              child:
                  CustomPaint(painter: _DonutPainter(donutData: donutData)),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: donutData.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
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
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.luxuryText,
                        ),
                      ),
                    ),
                    Text(
                      '${(d.pct * 100).round()}%',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.luxuryEspresso,
                      ),
                    ),
                  ]),
                );
              }).toList()),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartCard(
      List<WeeklyActivityDay> activity, int currentXp, int weeklyProgress) {
    return WeeklyChart(
      days: activity,
      currentXp: currentXp,
      weeklyXpGoal: 500,
    );
  }

  Widget _buildSkillsCard(List<SkillItem> skills) {
    if (skills.isEmpty) return const SizedBox.shrink();
    return _DoubleBezel(
      borderRadius: 14,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('\u{1F4DA}',
                style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Ky nang',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.luxuryEspresso,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ...skills.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.title,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.luxuryEspresso,
                            ),
                          ),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                              '${s.accuracy.round()}%',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.luxuryBrown,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${s.completed} bai',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: AppColors.luxuryText,
                              ),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (s.accuracy / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.luxuryBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            s.accuracy >= 80
                                ? AppColors.luxuryGreen
                                : s.accuracy >= 50
                                    ? AppColors.luxuryGold
                                    : AppColors.luxuryDanger,
                          ),
                        ),
                      ),
                    ]),
              )),
        ],
      ),
    );
  }

  Widget _buildCalendarHeatmap({required List<int> heatLevels}) {
    return _DoubleBezel(
      borderRadius: 14,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lich hoc 14 tuan gan day',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.luxuryEspresso,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 118,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 14,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 0.7,
              ),
              itemCount: 98,
              itemBuilder: (context, index) {
                final level =
                    index < heatLevels.length ? heatLevels[index] : 0;
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
        return AppColors.luxuryGreen.withValues(alpha: 0.25);
      case 2:
        return AppColors.luxuryGreen.withValues(alpha: 0.50);
      case 3:
        return AppColors.luxuryGreen.withValues(alpha: 0.80);
      case 4:
        return AppColors.luxuryGreen;
      default:
        return AppColors.luxuryBorder.withValues(alpha: 0.5);
    }
  }

  Widget _buildBadgesSection(
      {required List<({String icon, String name, bool locked})> badges}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          'Huy hieu',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.luxuryEspresso,
          ),
        ),
      ),
      if (badges.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Chua co huy hieu nao. Hoc tap cham chi de mo khoa!',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.luxuryTextHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        )
      else
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children:
              badges.map((b) => _badgeItem(b.icon, b.name, b.locked)).toList(),
        ),
    ]);
  }

  Widget _badgeItem(String icon, String name, bool locked) {
    return SizedBox(
      width: 80,
      child: Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: locked
                  ? AppColors.luxuryBorder
                  : AppColors.luxuryGold,
              width: 2,
            ),
            color: locked
                ? AppColors.luxuryBorder.withValues(alpha: 0.3)
                : AppColors.luxuryGold.withValues(alpha: 0.08),
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(
                fontSize: 20,
                color: locked ? AppColors.luxuryTextHint : null,
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
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color:
                locked ? AppColors.luxuryTextHint : AppColors.luxuryText,
          ),
        ),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<({String label, double pct, Color color})> donutData;
  _DonutPainter({required this.donutData});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 8;
    const strokeW = 16.0;
    final bgPaint = Paint()
      ..color = AppColors.luxuryBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);
    double currentAngle = -math.pi / 2;
    for (final segment in donutData) {
      if (segment.pct <= 0) continue;
      final sweepAngle = 2 * math.pi * segment.pct;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          currentAngle, sweepAngle, false, paint);
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
