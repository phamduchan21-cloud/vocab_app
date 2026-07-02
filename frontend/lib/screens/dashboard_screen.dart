import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/streak_bar.dart';
import '../widgets/review_card.dart';
import '../widgets/skill_grid.dart';
import '../widgets/stats_grid.dart';
import '../widgets/progress_bar_skill.dart';
import '../widgets/mock_test_card.dart';
import '../widgets/leaderboard_preview.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      drawer: const AppDrawer(),
      body: _buildBody(context, dashboard),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBody(BuildContext context, DashboardProvider dashboard) {
    if (dashboard.isLoading && dashboard.data == null) {
      return _buildLoadingSkeleton();
    }

    if (dashboard.errorMessage != null && dashboard.data == null) {
      return Scaffold(
        appBar: _buildAppBar(context),
        drawer: const AppDrawer(),
        body: ErrorStateWidget(
          message: dashboard.errorMessage!,
          onRetry: () => dashboard.loadDashboard(),
        ),
      );
    }

    if (dashboard.data == null ||
        (dashboard.data!.stats.vocabCount == 0 &&
            dashboard.data!.stats.quizCount == 0)) {
      return Scaffold(
        appBar: _buildAppBar(context),
        drawer: const AppDrawer(),
        body: _buildEmptyWelcome(context, dashboard),
      );
    }

    final data = dashboard.data!;

    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () => dashboard.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Section 1: Streak Bar
            SliverToBoxAdapter(
              child: StreakBar(stats: data.stats),
            ),

            // Section 2: Spaced Repetition Review
            SliverToBoxAdapter(
              child: ReviewCard(
                data: data.review,
                onTap: () => context.go('/quiz/play'),
                onRetry: () => dashboard.loadDashboard(),
              ),
            ),

            // Section 3: 4 Kỹ năng Grid 2×2 (Migii style)
            SliverToBoxAdapter(
              child: SkillGrid(
                skills: data.skills,
                onSkillTap: (type, title) {
                  context.go('/skill/$type');
                },
              ),
            ),

            // Section 4: Stats Grid
            SliverToBoxAdapter(
              child: StatsGrid(stats: data.stats),
            ),

            // Section 5: Progress Bar từng kỹ năng
            SliverToBoxAdapter(
              child: ProgressBarSkill(skills: data.skills),
            ),

            // Section 6: Luyện đề thi (Mock Test)
            SliverToBoxAdapter(
              child: MockTestCard(
                beginnerCompleted: data.topik1Completed,
                beginnerTotal: data.topik1Total,
                advancedCompleted: data.topik2Completed,
                advancedTotal: data.topik2Total,
                onBeginnerTap: () => context.go('/quiz/play'),
                onAdvancedTap: () => context.go('/quiz/play'),
              ),
            ),

            // Section 7: Bảng xếp hạng
            SliverToBoxAdapter(
              child: LeaderboardPreview(
                entries: data.leaderboard,
                onSeeAll: () => context.go('/quiz/history'),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'MeuBeu',
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: AppColors.primary,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textSecondary,
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.person_outline),
            color: AppColors.textSecondary,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Home', 0, () {
                setState(() => _currentNavIndex = 0);
                if (ModalRoute.of(context)?.settings.name != '/') context.go('/');
              }),
              _navItem(Icons.quiz_rounded, 'Quiz', 1, () {
                setState(() => _currentNavIndex = 1);
                context.go('/quiz');
              }),
              _navItem(Icons.assignment_rounded, 'Thi', 2, () {
                setState(() => _currentNavIndex = 2);
                context.go('/mock-test');
              }),
              _navItem(Icons.person_rounded, 'Hồ sơ', 3, () {
                setState(() => _currentNavIndex = 3);
                Scaffold.of(context).openDrawer();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, VoidCallback onTap) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.textHint,
            size: 26,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWelcome(BuildContext context, DashboardProvider dashboard) {
    return RefreshIndicator(
      onRefresh: () => dashboard.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreakBar(stats: dashboard.data?.stats),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text('🐱', style: TextStyle(fontSize: 80, color: AppColors.primary)),
                const SizedBox(height: 16),
                Text(
                  'Chào mừng đến với MeuBeu!',
                  style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Học từ vựng tiếng Anh mỗi ngày!',
                  style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                _buildStartButton(context, 'Thêm từ vựng đầu tiên', Icons.add_rounded, () => context.go('/vocabulary/new')),
                const SizedBox(height: 12),
                _buildStartButton(context, 'Làm quiz ngay', Icons.quiz_rounded, () => context.go('/quiz')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
      body: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 8),
            StreakBar(isLoading: true),
            SizedBox(height: 8),
            ReviewCard(isLoading: true),
            SizedBox(height: 8),
            SkillGrid(isLoading: true),
            SizedBox(height: 8),
            StatsGrid(isLoading: true),
            SizedBox(height: 8),
            ProgressBarSkill(isLoading: true),
            SizedBox(height: 8),
            MockTestCard(isLoading: true),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
