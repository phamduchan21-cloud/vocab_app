import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/dashboard_data.dart';
import '../models/profile_data.dart';
import '../models/quiz_result.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboard = context.read<DashboardProvider>();
      final profile = context.read<ProfileProvider>();
      if (dashboard.data == null && !dashboard.isLoading) {
        dashboard.loadDashboard();
      }
      profile.loadProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final profile = context.watch<ProfileProvider>();

    final user = auth.user;
    final email = user?.email ?? '---';
    final metadata = user?.userMetadata;
    final displayName = (metadata?['username'] as String?)?.trim();
    final fallbackName = email.contains('@') ? email.split('@').first : 'Học viên';
    final username = displayName?.isNotEmpty == true ? displayName! : fallbackName;
    final avatarText = username.isNotEmpty ? username[0].toUpperCase() : '?';

    final stats = dashboard.data?.stats ?? DashboardStats();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Hồ sơ học tập',
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfileSheet(username),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      body: RefreshIndicator(
        onRefresh: () async {
          await dashboard.loadDashboard();
          await profile.loadProfile();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _ProfileHero(
              avatarText: avatarText,
              username: username,
              email: email,
              englishLevel: profile.userProfile?.englishLevel,
              stats: stats,
              onClaimReward: profile.isClaimingReward
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final message = await profile.claimStreakReward();
                      if (!mounted || message == null) return;
                      messenger.showSnackBar(SnackBar(content: Text(message)));
                      await dashboard.loadDashboard();
                    },
            ),
            const SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.blue,
              unselectedLabelColor: AppColors.inkSoft,
              indicatorColor: AppColors.blue,
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Tiến độ'),
                Tab(text: 'Huy hiệu'),
                Tab(text: 'Tài khoản'),
              ],
            ),
            SizedBox(
              height: 680,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(stats: stats, recentQuizzes: profile.recentQuizzes),
                  _ProgressTab(
                    isLoading: profile.isLoading,
                    errorMessage: profile.errorMessage,
                    weeklyActivity: profile.data,
                    topics: dashboard.data?.topics ?? const [],
                  ),
                  _BadgeTab(
                    isLoading: profile.isLoading,
                    errorMessage: profile.errorMessage,
                    achievements: profile.achievements,
                  ),
                  _AccountTab(
                    email: email,
                    username: username,
                    englishLevel: profile.userProfile?.englishLevel,
                    onEdit: () => _showEditProfileSheet(username),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final profile = context.read<ProfileProvider>();
    final authProv = context.read<AuthProvider>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cập nhật tên hiển thị',
                style: GoogleFonts.workSans(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(sheetContext);
                    final navigator = Navigator.of(sheetContext);
                    final error = await profile.updateDisplayName(controller.text);
                    if (!mounted) return;
                    if (error != null) {
                      messenger.showSnackBar(SnackBar(content: Text(error)));
                      return;
                    }
                    authProv.setUser(authProv.user);
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật tên hiển thị.')),
                    );
                  },
                  child: const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Profile Hero ─────────────────────────────────────
class _ProfileHero extends StatefulWidget {
  final String avatarText, username, email;
  final String? englishLevel;
  final DashboardStats stats;
  final VoidCallback? onClaimReward;

  const _ProfileHero({
    required this.avatarText, required this.username, required this.email,
    this.englishLevel, required this.stats, required this.onClaimReward,
  });

  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero>
    with SingleTickerProviderStateMixin {
  AnimationController? _levelUpController;
  Animation<double>? _levelUpScale;

  @override
  void dispose() {
    _levelUpController?.dispose();
    super.dispose();
  }

  void _onClaimReward() {
    _levelUpController?.dispose();
    _levelUpController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _levelUpScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _levelUpController!, curve: Curves.elasticOut),
    );
    _levelUpController!.forward();
    _levelUpController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _levelUpController?.reverse();
        });
      }
    });
    widget.onClaimReward?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue, AppColors.blueContainer],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              // Decorative blurs
              Positioned(
                top: -30, right: -30,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        child: Text(
                          widget.avatarText,
                          style: GoogleFonts.workSans(
                            fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.username,
                              style: GoogleFonts.workSans(
                                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.email,
                              style: GoogleFonts.workSans(
                                fontSize: 13, color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _EnglishLevelBadge(
                              level: widget.englishLevel,
                              onTap: () => _showLevelPicker(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Stats row (Stitch semi-transparent container)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        _HeroMetric(label: 'Level', value: '${widget.stats.level}'),
                        _statDivider(),
                        _HeroMetric(label: 'XP', value: '${widget.stats.xp}'),
                        _statDivider(),
                        _HeroMetric(label: 'Streak', value: '${widget.stats.streak}'),
                        _statDivider(),
                        _HeroMetric(label: 'Gems', value: '${widget.stats.gems}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // CTA buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/progress'),
                          icon: const Icon(Icons.insights_outlined, size: 16),
                          label: const Text('Xem tiến độ'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onClaimReward,
                          icon: const Icon(Icons.local_fire_department_outlined, size: 16),
                          label: const Text('Nhận thưởng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.blueDark,
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
        // Level up animation overlay
        if (_levelUpController != null && _levelUpController!.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _levelUpController!,
                builder: (context, child) => Opacity(
                  opacity: _levelUpController!.value < 0.3
                      ? _levelUpController!.value / 0.3
                      : (1.0 - (_levelUpController!.value - 0.3) / 0.7).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _levelUpScale?.value ?? 0,
                    child: child,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎉', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 8),
                      Text('Level Up!', style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 20, color: Colors.black38)],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1, height: 28,
      color: Colors.white.withValues(alpha: 0.20),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label, value;
  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 11, color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

void _showLevelPicker(BuildContext context) {
  final profile = context.read<ProfileProvider>();
  final currentLevel = profile.userProfile?.englishLevel;
  final messenger = ScaffoldMessenger.of(context);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn trình độ tiếng Anh',
              style: GoogleFonts.workSans(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trình độ này giúp chúng tôi gợi ý nội dung phù hợp với bạn.',
              style: GoogleFonts.workSans(fontSize: 13, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),
            ...englishLevels.map((level) {
              final isSelected = level['key'] == currentLevel;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () async {
                    final error = await profile.updateEnglishLevel(level['key']!);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (!context.mounted) return;
                    if (error != null) {
                      messenger.showSnackBar(SnackBar(content: Text(error)));
                    } else {
                      messenger.showSnackBar(SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('Đã cập nhật trình độ: ${level['label']}'),
                      ));
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.blueBg : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.blue : AppColors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(level['emoji']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            level['label']!,
                            style: GoogleFonts.workSans(
                              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.blue),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}

class _EnglishLevelBadge extends StatelessWidget {
  final String? level;
  final VoidCallback onTap;
  const _EnglishLevelBadge({this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final emoji = getEnglishLevelEmoji(level) ?? '📚';
    final label = getEnglishLevelLabel(level);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label ?? 'Chưa xác định',
              style: GoogleFonts.workSans(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 12, color: Colors.white.withValues(alpha: 0.78)),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Tổng quan ────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final DashboardStats stats;
  final List<QuizResult> recentQuizzes;
  const _OverviewTab({required this.stats, required this.recentQuizzes});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
      children: [
        Row(
          children: [
            _MiniStatCard(
              label: 'Từ đã học', value: '${stats.vocabCount}',
              icon: Icons.menu_book_outlined, iconBg: AppColors.blueBg, iconColor: AppColors.blue,
            ),
            const SizedBox(width: 10),
            _MiniStatCard(
              label: 'Quiz đã làm', value: '${stats.quizCount}',
              icon: Icons.quiz_outlined, iconBg: AppColors.warningBg, iconColor: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _MiniStatCard(
              label: 'Độ chính xác', value: '${stats.accuracyRate.round()}%',
              icon: Icons.track_changes_outlined, iconBg: AppColors.successBg, iconColor: AppColors.success,
            ),
            const SizedBox(width: 10),
            _MiniStatCard(
              label: 'Tiến độ tuần', value: '${stats.weeklyProgress}%',
              icon: Icons.timelapse_outlined, iconBg: AppColors.blueBg, iconColor: AppColors.blue,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Quiz gần đây',
          style: GoogleFonts.workSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        if (recentQuizzes.isEmpty)
          const EmptyStateWidget(
            title: 'Chưa có bài quiz nào',
            subtitle: 'Làm một bài quiz để hiển thị lịch sử.',
            action: 'Mở quiz', showCat: false,
          )
        else
          ...recentQuizzes.take(4).map((item) => _QuizHistoryTile(item: item)),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconBg, iconColor;
  const _MiniStatCard({
    required this.label, required this.value, required this.icon,
    required this.iconBg, required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.workSans(fontSize: 12, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Tiến độ ───────────────────────────────────
class _ProgressTab extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<WeeklyActivityDay> weeklyActivity;
  final List<TopicProgressItem> topics;
  const _ProgressTab({
    required this.isLoading, required this.errorMessage,
    required this.weeklyActivity, required this.topics,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && weeklyActivity.isEmpty) {
      return const SkeletonLoading(type: SkeletonType.card);
    }
    if (errorMessage != null && weeklyActivity.isEmpty) {
      return ErrorStateWidget(
        message: errorMessage!,
        onRetry: () => context.read<ProfileProvider>().loadProfile(),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
      children: [
        _WeeklyActivityCard(days: weeklyActivity),
        const SizedBox(height: 18),
        Text(
          'Chủ đề nổi bật',
          style: GoogleFonts.workSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        ...topics.take(6).map((topic) => _TopicProgressTile(item: topic)),
      ],
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  final List<WeeklyActivityDay> days;
  const _WeeklyActivityCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final displayDays = days.isEmpty
        ? List.generate(7, (index) => WeeklyActivityDay(date: 'N/A', xp: 0, quizzes: 0, learned: 0))
        : days;
    final maxXp = displayDays.fold<int>(1, (max, day) => day.xp > max ? day.xp : max);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động 7 ngày',
            style: GoogleFonts.workSans(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: displayDays.map((day) {
              final height = maxXp == 0 ? 8.0 : 14 + (day.xp / maxXp) * 72;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        '${day.xp} XP',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10, color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TopicProgressTile extends StatelessWidget {
  final TopicProgressItem item;
  const _TopicProgressTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.topic,
                style: GoogleFonts.workSans(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink,
                ),
              ),
              Text(
                '${item.masteryPercent.round()}%',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.masteryPercent / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.mastered}/${item.total} từ đã nắm vững',
            style: GoogleFonts.workSans(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Huy hiệu ─────────────────────────────────
class _BadgeTab extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<AchievementItem> achievements;
  const _BadgeTab({
    required this.isLoading, required this.errorMessage, required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && achievements.isEmpty) {
      return const SkeletonLoading(type: SkeletonType.grid);
    }
    if (errorMessage != null && achievements.isEmpty) {
      return ErrorStateWidget(
        message: errorMessage!,
        onRetry: () => context.read<ProfileProvider>().loadProfile(),
      );
    }
    if (achievements.isEmpty) {
      return const EmptyStateWidget(
        title: 'Chưa mở khóa huy hiệu',
        subtitle: 'Học đều mỗi ngày để nhận huy hiệu.',
        action: 'Bắt đầu học', showCat: false,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final item = achievements[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceContainerHighest),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(item.icon ?? '🏆', style: const TextStyle(fontSize: 22)),
                ),
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.workSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description ?? 'Thành tích đã mở khóa',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.workSans(fontSize: 12, color: AppColors.inkSoft),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Tab 4: Tài khoản ─────────────────────────────────
class _AccountTab extends StatelessWidget {
  final String email, username;
  final String? englishLevel;
  final VoidCallback onEdit;
  const _AccountTab({
    required this.email, required this.username, this.englishLevel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
      children: [
        _ActionTile(
          icon: Icons.person_outline, title: 'Tên hiển thị', subtitle: username,
          onTap: onEdit,
        ),
        _ActionTile(
          icon: Icons.mail_outline, title: 'Email', subtitle: email,
          onTap: () {},
        ),
        _ActionTile(
          icon: Icons.school_outlined, title: 'Trình độ tiếng Anh',
          subtitle: getEnglishLevelLabel(englishLevel) ?? 'Chưa chọn',
          onTap: () => _showLevelPicker(context),
        ),
        _AccountDailyGoalTile(),
        _ActionTile(
          icon: Icons.history_outlined, title: 'Lịch sử quiz',
          subtitle: 'Xem chi tiết các bài quiz đã làm',
          onTap: () => context.go('/quiz/history'),
        ),
        _ActionTile(
          icon: Icons.bookmark_outline, title: 'Từ đã lưu',
          subtitle: 'Mở bộ sưu tập từ vựng đánh dấu',
          onTap: () => context.go('/bookmark'),
        ),
        _ActionTile(
          icon: Icons.logout_rounded, title: 'Đăng xuất',
          subtitle: 'Kết thúc phiên đăng nhập hiện tại',
          danger: true,
          onTap: () => context.read<AuthProvider>().logout(),
        ),
      ],
    );
  }
}

class _AccountDailyGoalTile extends StatefulWidget {
  @override
  State<_AccountDailyGoalTile> createState() => _AccountDailyGoalTileState();
}

class _AccountDailyGoalTileState extends State<_AccountDailyGoalTile> {
  double _sliderValue = 10;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    _sliderValue = (profile.userProfile?.dailyWordGoal ?? 10).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: AppColors.blue),
              const SizedBox(width: 10),
              Text(
                'Mục tiêu từ mới mỗi ngày',
                style: GoogleFonts.workSans(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('5', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.inkSoft)),
              Expanded(
                child: Slider(
                  value: _sliderValue, min: 5, max: 50, divisions: 9,
                  activeColor: AppColors.blue,
                  inactiveColor: AppColors.surfaceContainerHighest,
                  label: '${_sliderValue.round()} từ',
                  onChanged: (v) => setState(() => _sliderValue = v),
                  onChangeEnd: (v) => profile.updateDailyGoal(v.round()),
                ),
              ),
              Text('50', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.inkSoft)),
            ],
          ),
          Center(
            child: Text(
              '${_sliderValue.round()} từ / ngày',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool danger;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon, required this.title, required this.subtitle,
    required this.onTap, this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: ListTile(
        leading: Icon(icon, color: danger ? AppColors.danger : AppColors.blue),
        title: Text(
          title,
          style: GoogleFonts.workSans(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: danger ? AppColors.danger : AppColors.ink,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.workSans(fontSize: 12, color: AppColors.inkSoft),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}

// ─── Shared ──────────────────────────────────────────
class _QuizHistoryTile extends StatelessWidget {
  final QuizResult item;
  const _QuizHistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.blueBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${item.scorePercent.round()}%',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.topic?.isNotEmpty == true ? 'Quiz chủ đề ${item.topic}' : item.quizType,
                  style: GoogleFonts.workSans(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink,
                  ),
                ),
                Text(
                  '${item.correctAnswers}/${item.totalQuestions} câu đúng',
                  style: GoogleFonts.workSans(fontSize: 12, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
