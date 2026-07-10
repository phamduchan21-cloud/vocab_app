import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../data/mini_test_questions.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/topic_provider.dart';

import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/leaderboard_preview.dart';
import '../widgets/topic_grid.dart';
import '../widgets/hero_stats_bar.dart';
import '../widgets/daily_task_card.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/app_bottom_nav.dart';

// ─── Entry animation (spring cubic) ────────────────────
class _EntryAnimation extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _EntryAnimation({required this.child, this.delayMs = 0});

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
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
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
    final innerPad = padding ?? const EdgeInsets.all(16);
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

// ─── Luxury pill button with trailing icon island ──────
class _LuxuryPill extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;

  const _LuxuryPill({
    required this.label,
    this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.fromLTRB(24, 10, 10, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
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
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// DashboardScreen
// ════════════════════════════════════════════════════════

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int get _selectedNavIndex {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/quiz')) return 1;
    if (location.startsWith('/flashcard')) return 2;
    if (location.startsWith('/test') ||
        location.startsWith('/mock-test')) {
      return 3;
    }
    if (location.startsWith('/profile') ||
        location.startsWith('/progress') ||
        location.startsWith('/bookmark')) {
      return 4;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
      context.read<TopicProvider>().loadTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final username = user?.userMetadata?['username'] as String? ?? 'Ban';
    final profile = context.watch<ProfileProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;

        return AppBottomNavWrapper(
          selectedIndex: _selectedNavIndex,
          isWide: isWide,
          sidebar: isWide
              ? _Sidebar(
                  selectedIndex: _selectedNavIndex,
                  onItemSelected: (index) {
                    final routes = [
                      '/',
                      '/quiz',
                      '/flashcard',
                      '/test',
                      '/profile'
                    ];
                    context.go(routes[index]);
                  },
                  avatarLetter: username.isNotEmpty
                      ? username[0].toUpperCase()
                      : 'V',
                  displayName: username,
                  levelLabel: 'CAP ${dashboard.data?.stats.level ?? '-'}',
                )
              : null,
          body: _buildMainContent(context, dashboard, username, profile),
        );
      },
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    DashboardProvider dashboard,
    String username,
    ProfileProvider profile,
  ) {
    if (dashboard.isLoading && dashboard.data == null) {
      return _buildLoading();
    }

    if (dashboard.errorMessage != null && dashboard.data == null) {
      return _buildError(dashboard);
    }

    if (dashboard.data == null ||
        (dashboard.data!.stats.vocabCount == 0 &&
            dashboard.data!.stats.quizCount == 0)) {
      return _buildEmpty(dashboard, username);
    }

    final data = dashboard.data!;
    final stats = data.stats;
    final review = data.review;
    final dailyGoal = profile.userProfile?.dailyWordGoal ?? 10;
    final hasDoneQuizToday = stats.quizCount > 0;
    final dailyProgress = review.total > 0
        ? review.completed
        : stats.vocabCount.clamp(0, dailyGoal);
    final featuredTopic =
        MiniTestBank.topicKeys[DateTime.now().day % MiniTestBank.topicKeys.length];
    final featuredLabel =
        MiniTestBank.displayName(featuredTopic) ?? featuredTopic;

    return RefreshIndicator(
      color: AppColors.luxuryBrown,
      onRefresh: () => dashboard.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroStatsBar(
              displayName: username,
              streak: stats.streak,
              xp: stats.xp,
              gems: stats.gems,
              level: stats.level,
              levelTitle: stats.levelTitle,
              dailyGoal: dailyGoal,
              dailyProgress: dailyProgress,
              englishLevel: profile.userProfile?.englishLevel,
            ),

            const SizedBox(height: 28),

            // ─── Daily Tasks ─────────────────────────────
            _EntryAnimation(
              delayMs: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoc tap hom nay',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.luxuryEspresso,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 380;
                      if (isNarrow) {
                        return Column(
                          children: [
                            DailyTaskCard(
                              icon: Icons.style,
                              title: 'On tap flashcard',
                              description: review.remaining > 0
                                  ? '$review.remaining tu can on'
                                  : 'Hoc tu moi',
                              meta: review.remaining > 0
                                  ? '${review.remaining} tu'
                                  : null,
                              progress: review.total > 0
                                  ? review.completed / review.total
                                  : 0,
                              isDone: review.total > 0 && review.remaining == 0,
                              accentColor: AppColors.luxuryBrown,
                              onTap: () => context.go('/flashcard'),
                            ),
                            const SizedBox(height: 10),
                            DailyTaskCard(
                              icon: Icons.quiz,
                              title: 'Luyen tap quiz',
                              description: hasDoneQuizToday
                                  ? 'Da lam quiz hom nay!'
                                  : 'Trac nghiem 4 dap an',
                              isDone: hasDoneQuizToday,
                              accentColor: AppColors.luxuryGold,
                              onTap: () => context.go('/quiz'),
                            ),
                            const SizedBox(height: 10),
                            DailyTaskCard(
                              icon: Icons.assignment,
                              title: 'Kiem tra trinh do',
                              description: 'Mini-test tong hop',
                              accentColor: AppColors.luxuryDanger,
                              onTap: () => context.go('/test'),
                            ),
                            const SizedBox(height: 10),
                            DailyTaskCard(
                              icon: Icons.explore,
                              title: 'Kham pha kho tu',
                              description: 'Tham khao 300+ tu',
                              meta: '15 chu de',
                              accentColor: AppColors.luxuryGreen,
                              onTap: () => context.go('/topics'),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DailyTaskCard(
                                  icon: Icons.style,
                                  title: 'On tap flashcard',
                                  description: review.remaining > 0
                                      ? '$review.remaining tu can on'
                                      : 'Hoc tu moi',
                                  meta: review.remaining > 0
                                      ? '${review.remaining} tu'
                                      : null,
                                  progress: review.total > 0
                                      ? review.completed / review.total
                                      : 0,
                                  isDone: review.total > 0 &&
                                      review.remaining == 0,
                                  accentColor: AppColors.luxuryBrown,
                                  onTap: () => context.go('/flashcard'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DailyTaskCard(
                                  icon: Icons.quiz,
                                  title: 'Luyen tap quiz',
                                  description: hasDoneQuizToday
                                      ? 'Da lam quiz hom nay!'
                                      : 'Trac nghiem 4 dap an',
                                  isDone: hasDoneQuizToday,
                                  accentColor: AppColors.luxuryGold,
                                  onTap: () => context.go('/quiz'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DailyTaskCard(
                                  icon: Icons.assignment,
                                  title: 'Kiem tra trinh do',
                                  description: 'Mini-test tong hop',
                                  accentColor: AppColors.luxuryDanger,
                                  onTap: () => context.go('/test'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DailyTaskCard(
                                  icon: Icons.explore,
                                  title: 'Kham pha kho tu',
                                  description: 'Tham khao 300+ tu',
                                  meta: '15 chu de',
                                  accentColor: AppColors.luxuryGreen,
                                  onTap: () => context.go('/topics'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Streak reward hint ─────────────────────
            if (stats.streak >= 3 && !hasDoneQuizToday)
              _EntryAnimation(
                delayMs: 100,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.luxuryGold.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _DoubleBezel(
                      borderRadius: 14,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Text('\u{1F525}',
                              style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Streak ${stats.streak} ngay!',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.luxuryEspresso,
                                  ),
                                ),
                                Text(
                                  'Lam quiz hom nay de duy tri chuoi',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.luxuryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _LuxuryPill(
                            label: 'Luyen ngay',
                            color: AppColors.luxuryGold,
                            icon: Icons.bolt_rounded,
                            onPressed: () => context.go('/quiz'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ─── Topic of the Day ───────────────────────
            _EntryAnimation(
              delayMs: 150,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _DoubleBezel(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.luxuryBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.luxuryBorder),
                        ),
                        child: Center(
                          child: Text('\u{1F525}',
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.luxuryBrown,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CHU DE HOM NAY',
                                style: GoogleFonts.nunito(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              featuredLabel,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.luxuryEspresso,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hoc tu vung chu de nay ngay!',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppColors.luxuryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _LuxuryPill(
                        label: 'Hoc ngay',
                        color: AppColors.luxuryBrown,
                        onPressed: () {
                          context
                              .read<FlashcardProvider>()
                              .setTopic(featuredTopic);
                          context.go('/flashcard');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Weekly Progress ─────────────────────────
            _EntryAnimation(
              delayMs: 200,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: WeeklyChart(
                  days: profile.data,
                  currentXp: stats.xp,
                  weeklyXpGoal: 500,
                ),
              ),
            ),

            // ─── Topic Grid ─────────────────────────────
            if (data.topics.isNotEmpty) ...[
              _EntryAnimation(
                delayMs: 250,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: TopicGrid(
                    topics: data.topics,
                    onSeeAll: () => context.go('/topics'),
                    onTopicTap: (topic) async {
                      await context
                          .read<FlashcardProvider>()
                          .setTopic(topic);
                      if (context.mounted) {
                        context.go('/flashcard');
                      }
                    },
                  ),
                ),
              ),
            ],

            // ─── Leaderboard ───────────────────────────
            if (data.leaderboard.isNotEmpty) ...[
              _EntryAnimation(
                delayMs: 300,
                child: LeaderboardPreview(
                  entries: data.leaderboard,
                  onSeeAll: () => context.go('/profile'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoading(type: SkeletonType.card),
          SizedBox(height: 16),
          SkeletonLoading(type: SkeletonType.grid, count: 4),
          SizedBox(height: 16),
          SkeletonLoading(type: SkeletonType.card, count: 2),
          SizedBox(height: 16),
          SkeletonLoading(type: SkeletonType.list, count: 5),
        ],
      ),
    );
  }

  Widget _buildError(DashboardProvider dashboard) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ErrorStateWidget(
          message: dashboard.errorMessage!,
          onRetry: () => dashboard.loadDashboard(),
        ),
      ),
    );
  }

  Widget _buildEmpty(DashboardProvider dashboard, String username) {
    return RefreshIndicator(
      color: AppColors.luxuryBrown,
      onRefresh: () => dashboard.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroStatsBar(
              displayName: username,
              streak: dashboard.data?.stats.streak ?? 0,
              xp: dashboard.data?.stats.xp ?? 0,
              gems: dashboard.data?.stats.gems ?? 0,
              level: dashboard.data?.stats.level ?? 0,
              levelTitle: dashboard.data?.stats.levelTitle ?? 'Mam non',
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  const Text('\u{1F431}', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 12),
                  Text(
                    'Chao mung den voi VocaEng!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.luxuryEspresso,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hoc tu vung tieng Anh moi ngay!',
                    style: GoogleFonts.nunito(
                        fontSize: 15, color: AppColors.luxuryText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _StepGuide(
              step: '1',
              emoji: '\u{1F4DA}',
              title: 'Kham pha kho tu vung',
              color: AppColors.luxuryBrown,
              onTap: () => context.go('/topics'),
            ),
            const SizedBox(height: 10),
            _StepGuide(
              step: '2',
              emoji: '\u{1F0CF}',
              title: 'Hoc voi flashcard',
              color: AppColors.luxuryGold,
              onTap: () => context.go('/flashcard'),
            ),
            const SizedBox(height: 10),
            _StepGuide(
              step: '3',
              emoji: '\u{26A1}',
              title: 'Kiem tra voi quiz',
              color: AppColors.luxuryGreen,
              onTap: () => context.go('/quiz'),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Step Guide Card ──────────────────────────────────
class _StepGuide extends StatelessWidget {
  final String step, emoji, title;
  final Color color;
  final VoidCallback onTap;

  const _StepGuide({
    required this.step,
    required this.emoji,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.luxurySurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.luxuryBorder),
          ),
          padding: const EdgeInsets.all(2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.luxuryBorder.withValues(alpha: 0.45)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          step,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(emoji,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                title,
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.luxuryEspresso,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.luxuryText, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Desktop Sidebar ─────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String avatarLetter, displayName, levelLabel;

  const _Sidebar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.avatarLetter,
    required this.displayName,
    required this.levelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: AppColors.luxuryEspresso,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VocaEng',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.luxuryBeige,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'HOC TU VUNG',
            style: GoogleFonts.nunito(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              color: AppColors.luxuryTextHint,
            ),
          ),
          const SizedBox(height: 30),
          ...List.generate(_navData.length, (i) {
            final item = _navData[i];
            return _SidebarNavItem(
              icon: item.icon,
              label: item.label,
              isActive: i == selectedIndex,
              onTap: () => onItemSelected(i),
            );
          }),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: AppColors.luxuryGradient,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.luxuryBeige,
                    ),
                  ),
                  Text(
                    levelLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.luxuryTextHint,
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

  static const _navData = [
    _SidebarNavData(Icons.home_outlined, 'Trang chu'),
    _SidebarNavData(Icons.quiz_outlined, 'Quiz'),
    _SidebarNavData(Icons.style_outlined, 'Flashcard'),
    _SidebarNavData(Icons.assignment_outlined, 'Mini-test'),
    _SidebarNavData(Icons.person_outlined, 'Ho so'),
  ];
}

class _SidebarNavData {
  final IconData icon;
  final String label;
  const _SidebarNavData(this.icon, this.label);
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.luxuryBeige
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? AppColors.luxuryEspresso
                      : AppColors.luxuryBrownPale,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? AppColors.luxuryEspresso
                        : AppColors.luxuryBrownPale,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Wrapper: bottom nav mobile, sidebar desktop ─────
class AppBottomNavWrapper extends StatelessWidget {
  final int selectedIndex;
  final bool isWide;
  final Widget? sidebar;
  final Widget body;

  const AppBottomNavWrapper({
    super.key,
    required this.selectedIndex,
    required this.isWide,
    this.sidebar,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      body: isWide && sidebar != null
          ? Row(
              children: [
                sidebar!,
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar:
          isWide ? null : AppBottomNav(selectedIndex: selectedIndex),
    );
  }
}
