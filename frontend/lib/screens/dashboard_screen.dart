import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/topic_provider.dart';

import '../widgets/error_state_widget.dart';
import '../widgets/leaderboard_preview.dart';
import '../widgets/topic_grid.dart';
import '../widgets/hero_stats_bar.dart';
import '../widgets/daily_task_card.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/app_bottom_nav.dart';

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
    if (location.startsWith('/test') || location.startsWith('/mock-test')) return 3;
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
    final username = user?.userMetadata?['username'] as String? ?? 'Bạn';
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
                    final routes = ['/', '/quiz', '/flashcard', '/test', '/profile'];
                    context.go(routes[index]);
                  },
                  avatarLetter: username.isNotEmpty ? username[0].toUpperCase() : 'V',
                  displayName: username,
                  levelLabel: 'CẤP ${dashboard.data?.stats.level ?? '-'}',
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
    final dailyProgress = stats.vocabCount > 20 ? 8 : stats.vocabCount;
    final dailyGoal = profile.userProfile?.dailyWordGoal ?? 10;
    final hasDoneQuizToday = stats.quizCount > 0;

    // Featured topic
    final topicNames = [
      'greetings', 'family', 'numbers', 'daily', 'food', 'travel',
      'shopping', 'weather', 'health', 'work', 'education',
      'entertainment', 'technology', 'emotions', 'society',
    ];
    final featuredTopic = topicNames[DateTime.now().day % topicNames.length];

    return RefreshIndicator(
      onRefresh: () => dashboard.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Hero Stats Bar ──────────────────────────
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

            const SizedBox(height: 24),

            // ─── Daily Tasks (Bento Grid - Stitch style) ─
            Text(
              '📅 Học tập hôm nay',
              style: GoogleFonts.workSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            // Bento 2x2 grid
            _AnimatedSection(
              delayMs: 50,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 380;
                  return isNarrow
                      ? Column(
                          children: [
                            DailyTaskCard(
                              icon: Icons.style,
                              title: 'Ôn tập flashcard',
                              description: review.remaining > 0
                                  ? '$review.remaining từ cần ôn'
                                  : 'Học từ mới',
                              meta: review.remaining > 0 ? '${review.remaining} từ' : null,
                              progress: review.total > 0 ? review.completed / review.total : 0,
                              isDone: review.total > 0 && review.remaining == 0,
                              accentColor: AppColors.blue,
                              onTap: () => context.go('/flashcard'),
                            ),
                            const SizedBox(height: 10),
                            DailyTaskCard(
                              icon: Icons.quiz,
                              title: 'Luyện tập quiz',
                              description: hasDoneQuizToday
                                  ? 'Đã làm quiz hôm nay!'
                                  : 'Trắc nghiệm 4 đáp án',
                              isDone: hasDoneQuizToday,
                              accentColor: AppColors.warning,
                              onTap: () => context.go('/quiz'),
                            ),
                            const SizedBox(height: 10),
                            DailyTaskCard(
                              icon: Icons.assignment,
                              title: 'Kiểm tra trình độ',
                              description: 'Mini-test tổng hợp',
                              accentColor: AppColors.danger,
                              onTap: () => context.go('/test'),
                            ),
                            const SizedBox(height: 10),
                            DailyTaskCard(
                              icon: Icons.explore,
                              title: 'Khám phá kho từ',
                              description: 'Tham khảo 300+ từ',
                              meta: '15 chủ đề',
                              accentColor: AppColors.success,
                              onTap: () => context.go('/topics'),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DailyTaskCard(
                                    icon: Icons.style,
                                    title: 'Ôn tập flashcard',
                                    description: review.remaining > 0
                                        ? '$review.remaining từ cần ôn'
                                        : 'Học từ mới',
                                    meta: review.remaining > 0 ? '${review.remaining} từ' : null,
                                    progress: review.total > 0 ? review.completed / review.total : 0,
                                    isDone: review.total > 0 && review.remaining == 0,
                                    accentColor: AppColors.blue,
                                    onTap: () => context.go('/flashcard'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DailyTaskCard(
                                    icon: Icons.quiz,
                                    title: 'Luyện tập quiz',
                                    description: hasDoneQuizToday
                                        ? 'Đã làm quiz hôm nay!'
                                        : 'Trắc nghiệm 4 đáp án',
                                    isDone: hasDoneQuizToday,
                                    accentColor: AppColors.warning,
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
                                    title: 'Kiểm tra trình độ',
                                    description: 'Mini-test tổng hợp',
                                    accentColor: AppColors.danger,
                                    onTap: () => context.go('/test'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DailyTaskCard(
                                    icon: Icons.explore,
                                    title: 'Khám phá kho từ',
                                    description: 'Tham khảo 300+ từ',
                                    meta: '15 chủ đề',
                                    accentColor: AppColors.success,
                                    onTap: () => context.go('/topics'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ─── Topic of the Day (Stitch style) ──────────
            _AnimatedSection(
              delayMs: 150,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '🔥',
                          style: TextStyle(fontSize: 28),
                        ),
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
                              color: AppColors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CHỦ ĐỀ HÔM NAY',
                              style: GoogleFonts.workSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            featuredTopic[0].toUpperCase() +
                                featuredTopic.substring(1),
                            style: GoogleFonts.workSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Học từ vựng chủ đề này ngay!',
                            style: GoogleFonts.workSans(
                              fontSize: 12,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        context.read<FlashcardProvider>().setTopic(featuredTopic);
                        context.go('/flashcard');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Học ngay'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Weekly Progress ─────────────────────────
            _AnimatedSection(
              delayMs: 200,
              child: WeeklyChart(
                days: [],
                currentXp: stats.xp,
                weeklyXpGoal: 500,
              ),
            ),

            const SizedBox(height: 24),

            // ─── Topic Grid ─────────────────────────────
            if (data.topics.isNotEmpty) ...[
              _AnimatedSection(
                delayMs: 250,
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
              const SizedBox(height: 24),
            ],

            // ─── Leaderboard ───────────────────────────
            if (data.leaderboard.isNotEmpty) ...[
              _AnimatedSection(
                delayMs: 300,
                child: LeaderboardPreview(
                  entries: data.leaderboard,
                  onSeeAll: () => context.go('/profile'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
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
              levelTitle: dashboard.data?.stats.levelTitle ?? 'Mầm non',
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  const Text('🐱', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 12),
                  Text(
                    'Chào mừng đến với VocaEng!',
                    style: GoogleFonts.workSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Học từ vựng tiếng Anh mỗi ngày!',
                    style: GoogleFonts.workSans(
                        fontSize: 15, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _StepGuide(
              step: '1',
              emoji: '📚',
              title: 'Khám phá kho từ vựng',
              color: AppColors.blue,
              onTap: () => context.go('/topics'),
            ),
            const SizedBox(height: 10),
            _StepGuide(
              step: '2',
              emoji: '🃏',
              title: 'Học với flashcard',
              color: AppColors.warning,
              onTap: () => context.go('/flashcard'),
            ),
            const SizedBox(height: 10),
            _StepGuide(
              step: '3',
              emoji: '⚡',
              title: 'Kiểm tra với quiz',
              color: AppColors.success,
              onTap: () => context.go('/quiz'),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Animated Section (fade + slide up on appear) ────────
class _AnimatedSection extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _AnimatedSection({required this.child, this.delayMs = 0});

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  bool _hasAppeared = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAppeared && mounted) {
        Future.delayed(Duration(milliseconds: widget.delayMs), () {
          if (mounted) _controller.forward();
        });
        _hasAppeared = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ─── Step Guide Card for new users ─────────────────────
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHighest),
          ),
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
                    style: GoogleFonts.ibmPlexMono(
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
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: GoogleFonts.workSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.inkSoft, size: 20),
            ],
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
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VocaEng',
            style: GoogleFonts.workSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEDE6D3),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'HỌC TỪ VỰNG',
            style: GoogleFonts.workSans(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9AA3B8),
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
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: GoogleFonts.workSans(
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
                    style: GoogleFonts.workSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEDE6D3),
                    ),
                  ),
                  Text(
                    levelLabel,
                    style: GoogleFonts.workSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9AA3B8),
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
    _SidebarNavData(Icons.home_outlined, 'Trang chủ'),
    _SidebarNavData(Icons.quiz_outlined, 'Quiz'),
    _SidebarNavData(Icons.style_outlined, 'Flashcard'),
    _SidebarNavData(Icons.assignment_outlined, 'Mini-test'),
    _SidebarNavData(Icons.person_outlined, 'Hồ sơ'),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEDE6D3) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? AppColors.ink
                      : const Color(0xFFD6D1C0),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? AppColors.ink
                        : const Color(0xFFD6D1C0),
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

// ─── Wrapper: bottom nav mobile, sidebar desktop ──────
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
      backgroundColor: AppColors.background,
      body: isWide && sidebar != null
          ? Row(
              children: [
                sidebar!,
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide ? null : AppBottomNav(selectedIndex: selectedIndex),
    );
  }
}
