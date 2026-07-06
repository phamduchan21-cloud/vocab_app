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
    if (location.startsWith('/profile') || location.startsWith('/progress') || location.startsWith('/bookmark')) return 4;
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

    // KHÔNG dùng nested Scaffold — dùng LayoutBuilder với Container thay vì Scaffold con
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
    // Calculate daily progress from vocab count vs daily goal
    final dailyProgress = stats.vocabCount > 20 ? 8 : stats.vocabCount;
    final dailyGoal = profile.userProfile?.dailyWordGoal ?? 10;

    // Check if there are quiz results
    final hasDoneQuizToday = stats.quizCount > 0;

    // Featured topic (rotate based on day of week)
    final topicNames = [
      'greetings', 'family', 'numbers', 'daily', 'food', 'travel',
      'shopping', 'weather', 'health', 'work', 'education',
      'entertainment', 'technology', 'emotions', 'society',
    ];
    final featuredTopic = topicNames[DateTime.now().day % topicNames.length];

    // KHÔNG dùng GestureDetector bao bọc — nó chặn tap từ child InkWell
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

            const SizedBox(height: 22),

            // ─── Học tập hôm nay ─────────────────────────
            Text(
              '📅 Học tập hôm nay',
              style: GoogleFonts.workSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),

            DailyTaskCard(
              emoji: '🗂️',
              title: 'Ôn tập flashcard',
              description: review.remaining > 0
                  ? '$review.remaining từ cần ôn hôm nay'
                  : 'Học từ mới để bắt đầu ôn tập',
              meta: review.remaining > 0 ? '${review.remaining} từ' : null,
              progress: review.total > 0 ? review.completed / review.total : 0,
              isDone: review.total > 0 && review.remaining == 0,
              accentColor: AppColors.blue,
              onTap: () => context.go('/flashcard'),
            ),

            DailyTaskCard(
              emoji: '⚡',
              title: 'Luyện tập quiz',
              description: hasDoneQuizToday
                  ? 'Đã làm quiz hôm nay!'
                  : 'Trắc nghiệm 4 đáp án theo chủ đề',
              isDone: hasDoneQuizToday,
              accentColor: AppColors.warning,
              onTap: () => context.go('/quiz'),
            ),

            DailyTaskCard(
              emoji: '📝',
              title: 'Kiểm tra trình độ',
              description: 'Mini-test tổng hợp theo cấp độ',
              accentColor: AppColors.danger,
              onTap: () => context.go('/test'),
            ),

            DailyTaskCard(
              emoji: '📚',
              title: 'Khám phá kho từ vựng',
              description: 'Tham khảo 300+ từ theo 15 chủ đề',
              meta: '15 chủ đề',
              accentColor: AppColors.success,
              onTap: () => context.go('/topics'),
            ),

            const SizedBox(height: 22),

            // ─── Weekly Progress ─────────────────────────
            WeeklyChart(
              days: const [],
              currentXp: stats.xp,
              weeklyXpGoal: 500,
            ),

            const SizedBox(height: 22),

            // ─── Featured Topic ─────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blueLight, AppColors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔥 Chủ đề hôm nay',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          featuredTopic[0].toUpperCase() + featuredTopic.substring(1),
                          style: GoogleFonts.workSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Học từ vựng chủ đề này ngay!',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<FlashcardProvider>().setTopic(featuredTopic);
                        context.go('/flashcard');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.blueDark,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Học ngay'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ─── Danh mục chủ đề ───────────────────────
            if (data.topics.isNotEmpty) ...[
              TopicGrid(
                topics: data.topics,
                onSeeAll: () => context.go('/topics'),
                onTopicTap: (topic) async {
                  await context.read<FlashcardProvider>().setTopic(topic);
                  if (context.mounted) {
                    context.go('/flashcard');
                  }
                },
              ),
              const SizedBox(height: 22),
            ],

            // ─── Bảng xếp hạng ─────────────────────────
            if (data.leaderboard.isNotEmpty) ...[
              LeaderboardPreview(
                entries: data.leaderboard,
                onSeeAll: () => context.go('/profile'),
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
            // Welcome section
            Center(
              child: Column(
                children: [
                  const Text('🐱', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 12),
                  Text(
                    'Chào mừng đến với VocaEng!',
                    style: GoogleFonts.workSans(
                      fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Học từ vựng tiếng Anh mỗi ngày!',
                    style: GoogleFonts.workSans(fontSize: 15, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Step guide for new user
            _StepGuide(
              step: '1',
              emoji: '📚',
              title: 'Khám phá kho từ vựng',
              subtitle: 'Chọn chủ đề yêu thích từ 15+ bộ từ có sẵn',
              color: AppColors.blue,
              onTap: () => context.go('/topics'),
            ),
            const SizedBox(height: 10),
            _StepGuide(
              step: '2',
              emoji: '🃏',
              title: 'Học với flashcard',
              subtitle: 'Lật thẻ, ôn tập và ghi nhớ từ mới mỗi ngày',
              color: AppColors.warning,
              onTap: () => context.go('/flashcard'),
            ),
            const SizedBox(height: 10),
            _StepGuide(
              step: '3',
              emoji: '⚡',
              title: 'Kiểm tra với quiz',
              subtitle: 'Làm quiz 10 câu để kiểm tra kiến thức',
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

// ─── Step Guide Card for new users ─────────────────────
class _StepGuide extends StatelessWidget {
  final String step, emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _StepGuide({
    required this.step, required this.emoji, required this.title,
    required this.subtitle, required this.color, required this.onTap,
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
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              // Step number circle
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 14, fontWeight: FontWeight.w700,
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
                          title, style: GoogleFonts.workSans(
                            fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle, style: GoogleFonts.workSans(
                        fontSize: 12, color: AppColors.inkSoft,
                      ),
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

// ─── Sidebar (Desktop) ─────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String avatarLetter, displayName, levelLabel;

  const _Sidebar({
    required this.selectedIndex, required this.onItemSelected,
    required this.avatarLetter, required this.displayName, required this.levelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230, color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VocaEng',
            style: GoogleFonts.workSans(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: const Color(0xFFEDE6D3),
            )),
          const SizedBox(height: 6),
          Text('HỌC TỪ VỰNG',
            style: GoogleFonts.workSans(
              fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w500,
              color: const Color(0xFF9AA3B8),
            )),
          const SizedBox(height: 30),
          ...List.generate(_navData.length, (i) {
            final item = _navData[i];
            return _SidebarNavItem(
              icon: item.icon, label: item.label,
              isActive: i == selectedIndex,
              onTap: () => onItemSelected(i),
            );
          }),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blue, borderRadius: BorderRadius.circular(17),
                ),
                child: Center(child: Text(avatarLetter,
                  style: GoogleFonts.workSans(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white))),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                    style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFEDE6D3))),
                  Text(levelLabel,
                    style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF9AA3B8))),
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
    required this.icon, required this.label,
    required this.isActive, required this.onTap,
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
                Icon(icon, size: 18,
                  color: isActive ? AppColors.ink : const Color(0xFFD6D1C0)),
                const SizedBox(width: 12),
                Text(label,
                  style: GoogleFonts.workSans(
                    fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppColors.ink : const Color(0xFFD6D1C0),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Wrapper: bottom nav trên mobile, sidebar layout trên desktop ──────
// Giải quyết lỗi nested Scaffold: chỉ có 1 Scaffold, tránh gesture conflict.
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
