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
import '../motion/app_motion.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';

// ═════════════════════════════════════════════════════════════════════════
// PROFILE SCREEN — Editorial Luxury
// Warm cream/beige palette · Double-Bezel bento · Playful elegance
// Asymmetrical grid · Staggered entrance · Micro-motion spring
// ═════════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _heroCtrl;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final AnimationController _contentCtrl;
  late final Animation<double> _contentFade;

  static const _spring = Cubic(0.34, 1.56, 0.64, 1);
  static const _slide = Cubic(0.22, 1, 0.36, 1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Hero entrance — slides up with spring bounce
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroFade = CurvedAnimation(
      parent: _heroCtrl,
      curve: const Interval(0, 0.5, curve: _spring),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _heroCtrl,
            curve: const Interval(0, 0.5, curve: _spring),
          ),
        );

    // Content entrance — fades in after hero
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFade = CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0, 1, curve: _slide),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppMotion.reduced(context)) {
        _heroCtrl.value = 1;
        _contentCtrl.value = 1;
      } else {
        _heroCtrl.forward().then((_) => _contentCtrl.forward());
      }
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
    _heroCtrl.dispose();
    _contentCtrl.dispose();
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
    final profileName = profile.userProfile?.username?.trim();
    final metadataName = (metadata?['username'] as String?)?.trim();
    final fallbackName = email.contains('@')
        ? email.split('@').first
        : 'Học viên';
    final username = profileName?.isNotEmpty == true
        ? profileName!
        : metadataName?.isNotEmpty == true
        ? metadataName!
        : fallbackName;
    final avatarText = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final stats = dashboard.data?.stats ?? DashboardStats();

    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: RefreshIndicator(
              color: AppColors.luxuryBrown,
              onRefresh: () async {
                await dashboard.loadDashboard();
                await profile.loadProfile();
              },
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _heroFade,
                        child: SlideTransition(
                          position: _heroSlide,
                          child: _buildHeroBento(
                            avatarText,
                            username,
                            email,
                            stats,
                            profile.learningPath.currentCefr,
                            profile.userProfile?.createdAt,
                            profile.userProfile?.dailyWordGoal ?? 10,
                            profile.rewardSummary.claimableCount,
                            profile.isClaimingReward ||
                                    profile.rewardSummary.claimableCount == 0
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final message = await profile
                                        .claimAllRewards();
                                    if (!mounted || message == null) return;
                                    await dashboard.loadDashboard();
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ProfileTabHeaderDelegate(
                      child: ColoredBox(
                        color: AppColors.luxuryBg,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                          child: FadeTransition(
                            opacity: _contentFade,
                            child: _buildGlassTabBar(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                body: FadeTransition(
                  opacity: _contentFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _JourneyTab(
                          isLoading: profile.isLoading,
                          errorMessage: profile.errorMessage,
                          path: profile.learningPath,
                          todayPlan: profile.todayPlan,
                          isUpdating: profile.isUpdatingProfile,
                          onContinue: () {
                            final route = profile.todayPlan.dueReviews > 0
                                ? '/flashcard'
                                : profile.todayPlan.activityRoute;
                            context.go(route);
                          },
                          onAdjustGoal: () => _tabController.animateTo(3),
                          onComplete: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final message = await profile
                                .completeCurrentPathStep();
                            if (!mounted || message == null) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          },
                        ),
                        _ProgressTab(
                          isLoading: profile.isLoading,
                          errorMessage: profile.errorMessage,
                          stats: stats,
                          recentQuizzes: profile.recentQuizzes,
                          weeklyActivity: profile.data,
                          topics: dashboard.data?.topics ?? const [],
                        ),
                        _BadgeTab(
                          isLoading: profile.isLoading,
                          errorMessage: profile.errorMessage,
                          achievements: profile.achievements,
                          stats: stats,
                          rewardSummary: profile.rewardSummary,
                          rewards: profile.rewards,
                          rewardHistory: profile.rewardHistory,
                          isClaiming: profile.isClaimingReward,
                        ),
                        _AccountTab(
                          email: email,
                          username: username,
                          englishLevel: profile.userProfile?.englishLevel,
                          profile: profile.userProfile,
                          onEdit: () => _showEditProfileSheet(username),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // HERO — Editorial Luxury Bento
  // Double-Bezel outer shell · Cream gradient · Glass orbs
  // ═════════════════════════════════════════════════════════════════════

  String _joinedLabel(DateTime? createdAt) {
    if (createdAt == null) return 'Thành viên SolVocab';
    return 'Tham gia ${createdAt.month}/${createdAt.year}';
  }

  Widget _buildHeroBento(
    String avatarText,
    String username,
    String email,
    DashboardStats stats,
    String? englishLevel,
    DateTime? createdAt,
    int dailyWordGoal,
    int claimableRewards,
    VoidCallback? onClaimReward,
  ) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: AppColors.luxuryBrown.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.08),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              AppColors.surfaceSubtle,
              AppColors.surfaceContainer,
              AppColors.luxuryBorder,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.luxuryBrown.withValues(alpha: 0.08),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: AppColors.luxuryBrown.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ─── Decorative glass orbs ──────────────────
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.luxuryBrownPale.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.luxuryBeige.withValues(alpha: 0.05),
                ),
              ),
            ),
            // ─── Content ─────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + Info row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StampAvatar(initial: avatarText),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.luxuryEspresso,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppColors.luxuryText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _EnglishLevelBadge(
                              level: englishLevel,
                              onTap: () => _showLevelPicker(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_joinedLabel(createdAt)} · Mục tiêu $dailyWordGoal từ/ngày',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 10,
                                color: AppColors.luxuryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit — Double-Bezel button
                      IconButton(
                        tooltip: 'Chỉnh sửa hồ sơ',
                        onPressed: () => _showEditProfileSheet(username),
                        padding: EdgeInsets.zero,
                        icon: Container(
                          padding: const EdgeInsets.all(1.2),
                          decoration: BoxDecoration(
                            color: AppColors.luxuryBrown.withValues(
                              alpha: 0.05,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.luxuryBrown.withValues(
                                alpha: 0.10,
                              ),
                            ),
                          ),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.luxuryBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.luxuryBrown,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ─── Stats — Asymmetrical Bento ──────────
                  Row(
                    children: [
                      // Level — tall card (flex: 6)
                      Expanded(
                        flex: 6,
                        child: _statBentoCard(
                          value: stats.level,
                          label: 'Cấp độ',
                          icon: Icons.auto_awesome_rounded,
                          gradientColors: const [
                            AppColors.luxuryBrown,
                            AppColors.luxuryBrownLight,
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // XP — (flex: 5)
                      Expanded(
                        flex: 5,
                        child: _statBentoCard(
                          value: stats.xp,
                          label: 'XP',
                          icon: Icons.trending_up_rounded,
                          gradientColors: const [
                            AppColors.luxuryBrownPale,
                            AppColors.luxuryBrown,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _statBentoCard(
                          value: stats.streak,
                          label: 'Streak ngày',
                          icon: Icons.local_fire_department_rounded,
                          gradientColors: const [
                            AppColors.luxuryBeige,
                            AppColors.luxuryBrownPale,
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statBentoCard(
                          value: stats.gems,
                          label: 'Ngọc',
                          icon: Icons.diamond_rounded,
                          gradientColors: const [
                            AppColors.luxuryBrown,
                            AppColors.inverseSurface,
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ─── CTA Buttons — Double-Bezel glass ──
                  Row(
                    children: [
                      Expanded(
                        child: _GlassActionBtn(
                          label: 'Xem tiến độ',
                          icon: Icons.insights_rounded,
                          onTap: () => context.go('/progress'),
                          outlined: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlassActionBtn(
                          label: claimableRewards > 0
                              ? '$claimableRewards quà chờ'
                              : 'Chưa có quà',
                          icon: Icons.card_giftcard_rounded,
                          onTap: onClaimReward,
                          outlined: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // STAT BENTO CARD — warm gradient + double-bezel feel
  // ═════════════════════════════════════════════════════════════════════

  Widget _statBentoCard({
    required dynamic value,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(height: 14),
          Text(
            '$value',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // GLASS TAB BAR — editorial luxury
  // ═════════════════════════════════════════════════════════════════════

  Widget _buildGlassTabBar() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.luxuryBrown.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.luxuryText,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: const [AppColors.luxuryBrown, AppColors.luxuryBrownLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: AppColors.luxuryBrown.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Hành trình'),
          Tab(text: 'Thống kê'),
          Tab(text: 'Album tem'),
          Tab(text: 'Tài khoản'),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // EDIT PROFILE SHEET — editorial luxury modal
  // ═════════════════════════════════════════════════════════════════════

  Future<void> _showEditProfileSheet(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final profile = context.read<ProfileProvider>();
    final authProv = context.read<AuthProvider>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            28,
            24,
            28,
            28 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.luxurySurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.luxuryBrown.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cập nhật tên hiển thị',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryEspresso,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tên này được hiển thị trên hồ sơ và bảng xếp hạng',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.luxuryText,
                ),
              ),
              const SizedBox(height: 22),
              // Double-Bezel input
              Container(
                padding: const EdgeInsets.all(1.2),
                decoration: BoxDecoration(
                  color: AppColors.luxuryBrown.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.luxuryBrown.withValues(alpha: 0.08),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  decoration: BoxDecoration(
                    color: AppColors.luxuryBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: controller,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: AppColors.luxuryEspresso,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tên hiển thị',
                      labelStyle: GoogleFonts.nunito(
                        color: AppColors.luxuryText,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.luxuryText,
                        size: 20,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // Button-in-Button CTA
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.luxuryBrown,
                        AppColors.luxuryBrownLight,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.luxuryBrown.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(ctx);
                      final navigator = Navigator.of(ctx);
                      final error = await profile.updateDisplayName(
                        controller.text,
                      );
                      if (!mounted) return;
                      if (error != null) {
                        messenger.showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }
                      authProv.setUser(authProv.user);
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('✅ Đã cập nhật tên hiển thị.'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lưu thay đổi',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
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
            ],
          ),
        );
      },
    );
  }
}

class _ProfileTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _ProfileTabHeaderDelegate({required this.child});

  @override
  double get minExtent => 70;

  @override
  double get maxExtent => 70;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _ProfileTabHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}

// ═════════════════════════════════════════════════════════════════════════
// ENGLISH LEVEL BADGE — editorial chip
// ═════════════════════════════════════════════════════════════════════════

class _StampAvatar extends StatelessWidget {
  final String initial;

  const _StampAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.045,
      child: CustomPaint(
        painter: const _StampBorderPainter(),
        child: Container(
          width: 78,
          height: 86,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.luxuryBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.luxuryBrown.withValues(alpha: 0.32),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                initial,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  color: AppColors.luxuryEspresso,
                ),
              ),
              Text(
                'AIR MAIL',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 7,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampBorderPainter extends CustomPainter {
  const _StampBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.luxurySurface;
    const radius = 3.0;
    const step = 9.0;
    for (var x = 5.0; x < size.width; x += step) {
      canvas.drawCircle(Offset(x, 2), radius, paint);
      canvas.drawCircle(Offset(x, size.height - 2), radius, paint);
    }
    for (var y = 5.0; y < size.height; y += step) {
      canvas.drawCircle(Offset(2, y), radius, paint);
      canvas.drawCircle(Offset(size.width - 2, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EnglishLevelBadge extends StatelessWidget {
  final String? level;
  final VoidCallback onTap;
  const _EnglishLevelBadge({this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCefr = RegExp(r'^[AB][12]$').hasMatch(level ?? '');
    final emoji = isCefr ? '✈️' : getEnglishLevelEmoji(level) ?? '📚';
    final label = isCefr ? 'CEFR $level' : getEnglishLevelLabel(level);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.luxuryBrown.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.luxuryBrown.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              label ?? 'Chưa xác định',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryEspresso,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit_outlined,
              size: 10,
              color: AppColors.luxuryText.withValues(alpha: 0.60),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// GLASS ACTION BUTTON — editorial
// ═════════════════════════════════════════════════════════════════════════

class _GlassActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool outlined;

  const _GlassActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.transparent : AppColors.luxuryBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: outlined
                ? Border.all(
                    color: AppColors.luxuryBrown.withValues(alpha: 0.20),
                  )
                : null,
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                      color: AppColors.luxuryBrown.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: outlined
                    ? AppColors.luxuryBrown
                    : AppColors.luxuryEspresso,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: outlined
                      ? AppColors.luxuryBrown
                      : AppColors.luxuryEspresso,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// LEVEL PICKER — editorial modal
// ═════════════════════════════════════════════════════════════════════════

void _showLevelPicker(BuildContext context) {
  final profile = context.read<ProfileProvider>();
  final currentLevel = profile.learningPath.currentCefr;
  final messenger = ScaffoldMessenger.of(context);
  const cefrLevels = [
    {
      'key': 'A1',
      'emoji': '🛫',
      'label': 'A1 · Khởi hành',
      'description': 'Greetings, Family, Numbers, Daily Life',
    },
    {
      'key': 'A2',
      'emoji': '🧳',
      'label': 'A2 · Giao tiếp hằng ngày',
      'description': 'Food, Travel, Shopping, Weather',
    },
    {
      'key': 'B1',
      'emoji': '🌍',
      'label': 'B1 · Độc lập',
      'description': 'Health, Work, Education, Entertainment',
    },
    {
      'key': 'B2',
      'emoji': '🎓',
      'label': 'B2 · Tự tin học thuật',
      'description': 'Technology, Emotions, Society',
    },
  ];

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
        decoration: const BoxDecoration(
          color: AppColors.luxurySurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.luxuryBrown.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chọn chặng CEFR',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryEspresso,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lịch sử học vẫn được giữ nguyên khi bạn đổi chặng.',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.luxuryText,
              ),
            ),
            const SizedBox(height: 18),
            ...cefrLevels.map((level) {
              final isSelected = level['key'] == currentLevel;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () async {
                    if (isSelected) return;
                    final confirmed = await showDialog<bool>(
                      context: ctx,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(
                          'Chuyển sang ${level['key']}?',
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: const Text(
                          'Các chặng trước sẽ được đánh dấu miễn qua, không giả lập là đã học xong. Tiến trình cũ không bị xóa.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Giữ chặng hiện tại'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Xác nhận chuyển'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    final error = await profile.updateCefrLevel(level['key']!);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: error != null
                            ? AppColors.danger
                            : AppColors.luxuryBrown,
                        content: Text(
                          error ?? 'Đã cập nhật lộ trình: ${level['label']}',
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.luxuryBrown.withValues(alpha: 0.06)
                          : AppColors.luxurySurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.luxuryBrown
                            : AppColors.luxuryBrown.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          level['emoji']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level['label']!,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.luxuryEspresso,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                level['description']!,
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  color: AppColors.luxuryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.luxuryBrown,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
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

// ═════════════════════════════════════════════════════════════════════════
// TAB 1: HÀNH TRÌNH — CEFR route and adaptive daily plan
// ═════════════════════════════════════════════════════════════════════════

class _JourneyTab extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final LearningPathData path;
  final TodayLearningPlan todayPlan;
  final bool isUpdating;
  final VoidCallback onContinue;
  final VoidCallback onAdjustGoal;
  final VoidCallback onComplete;

  const _JourneyTab({
    required this.isLoading,
    required this.errorMessage,
    required this.path,
    required this.todayPlan,
    required this.isUpdating,
    required this.onContinue,
    required this.onAdjustGoal,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && path.steps.isEmpty) {
      return const SkeletonLoading(type: SkeletonType.card);
    }
    if (errorMessage != null && path.steps.isEmpty) {
      return ErrorStateWidget(
        message: errorMessage!,
        onRetry: () => context.read<ProfileProvider>().loadProfile(),
      );
    }
    if (path.steps.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          _JourneyEmptyState(
            onRetry: () => context.read<ProfileProvider>().loadProfile(),
          ),
        ],
      );
    }

    final current = path.current ?? path.steps.first;
    final skillHint = _skillHint(current);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
      physics: const BouncingScrollPhysics(),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final currentCard = _CurrentStageCard(
              step: current,
              overallProgress: path.overallProgress,
              skillHint: skillHint,
              isUpdating: isUpdating,
              onComplete: onComplete,
            );
            final planCard = _TodayPlanCard(
              plan: todayPlan,
              onContinue: onContinue,
              onAdjustGoal: onAdjustGoal,
            );
            if (constraints.maxWidth < 760) {
              return Column(
                children: [currentCard, const SizedBox(height: 14), planCard],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: currentCard),
                const SizedBox(width: 14),
                Expanded(flex: 5, child: planCard),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(
              Icons.flight_takeoff_rounded,
              size: 20,
              color: AppColors.luxuryBrown,
            ),
            const SizedBox(width: 8),
            Text(
              'Tuyến bay A1 → B2',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.luxuryEspresso,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CefrRoute(steps: path.steps),
      ],
    );
  }

  String _skillHint(LearningPathStep step) {
    final scores = <({String label, double value})>[
      (label: 'từ vựng', value: step.masteryPercent),
      (label: 'quiz', value: step.quizAverage),
      (label: 'mini test', value: step.miniTestScore),
    ]..sort((a, b) => a.value.compareTo(b.value));
    return scores.first.label;
  }
}

class _CurrentStageCard extends StatelessWidget {
  final LearningPathStep step;
  final double overallProgress;
  final String skillHint;
  final bool isUpdating;
  final VoidCallback onComplete;

  const _CurrentStageCard({
    required this.step,
    required this.overallProgress,
    required this.skillHint,
    required this.isUpdating,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (step.progressPercent / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.luxuryEspresso,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.luxuryEspresso.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'CHẶNG HIỆN TẠI',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                step.cefrLevel,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.luxuryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            step.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            step.description,
            style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${step.progressPercent.round()}% chặng',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${overallProgress.round()}% toàn hành trình',
                style: GoogleFonts.nunito(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(AppColors.luxuryGold),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                size: 17,
                color: AppColors.luxuryGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.canComplete
                      ? 'Bạn đã đủ điều kiện hoàn thành chặng.'
                      : 'Ưu tiên cải thiện $skillHint. ${step.reason}',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    height: 1.35,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          if (step.canComplete) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isUpdating ? null : onComplete,
                icon: const Icon(Icons.verified_rounded, size: 18),
                label: Text(isUpdating ? 'Đang xử lý...' : 'Hoàn thành chặng'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.luxuryGold,
                  foregroundColor: AppColors.luxuryEspresso,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  final TodayLearningPlan plan;
  final VoidCallback onContinue;
  final VoidCallback onAdjustGoal;

  const _TodayPlanCard({
    required this.plan,
    required this.onContinue,
    required this.onAdjustGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.today_rounded,
                color: AppColors.luxuryBrown,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Kế hoạch hôm nay',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryEspresso,
                ),
              ),
              const Spacer(),
              Text(
                '${plan.estimatedMinutes} phút',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PlanRow(
            icon: Icons.replay_rounded,
            label: 'Từ đến hạn ôn',
            value: '${plan.dueReviews}',
          ),
          _PlanRow(
            icon: Icons.add_circle_outline_rounded,
            label: 'Từ mới theo mục tiêu',
            value: '${plan.newWords}',
          ),
          _PlanRow(
            icon: Icons.headphones_rounded,
            label: plan.activityTitle,
            value: 'Ưu tiên',
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.luxuryBrown.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              plan.reason.isEmpty
                  ? 'Kế hoạch cân bằng 70% ôn tập và 30% từ mới.'
                  : plan.reason,
              style: GoogleFonts.nunito(
                fontSize: 11,
                height: 1.35,
                color: AppColors.luxuryText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.flight_rounded, size: 18),
              label: const Text('Tiếp tục hành trình'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.luxuryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: onAdjustGoal,
              child: const Text('Điều chỉnh mục tiêu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PlanRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.luxuryBrown),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.luxuryText,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.luxuryEspresso,
            ),
          ),
        ],
      ),
    );
  }
}

class _CefrRoute extends StatelessWidget {
  final List<LearningPathStep> steps;

  const _CefrRoute({required this.steps});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 760;
        if (desktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Expanded(child: _CefrStop(step: steps[index])),
                if (index < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 38),
                    child: Icon(
                      Icons.flight_rounded,
                      size: 20,
                      color: _statusColor(steps[index + 1].status),
                    ),
                  ),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              _CefrStop(step: steps[index]),
              if (index < steps.length - 1)
                Container(
                  width: 2,
                  height: 18,
                  color: _statusColor(
                    steps[index + 1].status,
                  ).withValues(alpha: 0.35),
                ),
            ],
          ],
        );
      },
    );
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'completed' => AppColors.success,
      'current' => AppColors.luxuryBrown,
      'waived' => AppColors.luxuryGold,
      _ => AppColors.luxuryTextHint,
    };
  }
}

class _CefrStop extends StatelessWidget {
  final LearningPathStep step;

  const _CefrStop({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = _CefrRoute._statusColor(step.status);
    final statusLabel = switch (step.status) {
      'completed' => 'Đã hoàn thành',
      'current' => 'Đang học',
      'waived' => 'Được miễn',
      _ => 'Chưa mở khóa',
    };
    final icon = switch (step.status) {
      'completed' => Icons.check_rounded,
      'current' => Icons.flight_takeoff_rounded,
      'waived' => Icons.fast_forward_rounded,
      _ => Icons.lock_outline_rounded,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.30)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            step.cefrLevel,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.luxuryEspresso,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            step.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.luxuryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (step.progressPercent / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.luxuryBorder,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyEmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _JourneyEmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.map_outlined,
            size: 42,
            color: AppColors.luxuryBrown,
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa thể tạo lộ trình',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.luxuryEspresso,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thử tải lại để hệ thống phân tích tiến độ học của bạn.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(color: AppColors.luxuryText),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tải lại lộ trình'),
          ),
        ],
      ),
    );
  }
}

// Retained as a reusable summary composition for future dashboard variants.
// ignore: unused_element
class _OverviewTab extends StatelessWidget {
  final DashboardStats stats;
  final List<QuizResult> recentQuizzes;
  final List<TopicProgressItem> topics;
  final List<WeeklyActivityDay> weeklyActivity;

  const _OverviewTab({
    required this.stats,
    required this.recentQuizzes,
    required this.topics,
    required this.weeklyActivity,
  });

  @override
  Widget build(BuildContext context) {
    final mastered = topics.fold<int>(0, (sum, item) => sum + item.mastered);
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        // ─── Asymmetrical Bento ──────────────────────
        Row(
          children: [
            Expanded(
              flex: 7,
              child: _BentoGradientCard(
                value: '${stats.vocabCount}',
                label: 'Từ đã học',
                icon: Icons.menu_book_rounded,
                colors: const [
                  AppColors.luxuryBrown,
                  AppColors.luxuryBrownLight,
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: _BentoGradientCard(
                value: '$mastered',
                label: 'Đã thành thạo',
                icon: Icons.workspace_premium_rounded,
                colors: const [
                  AppColors.luxuryBrownPale,
                  AppColors.luxuryBrown,
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BentoGradientCard(
                value: '${stats.quizCount}',
                label: 'Quiz đã làm',
                icon: Icons.quiz_rounded,
                colors: const [
                  AppColors.luxuryBeige,
                  AppColors.luxuryBrownPale,
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BentoGradientCard(
                value: '${stats.weeklyProgress}%',
                label: 'Tiến độ tuần',
                icon: Icons.timelapse_rounded,
                colors: const [AppColors.luxuryBrown, AppColors.inverseSurface],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        _ProfileActivitySummary(days: weeklyActivity),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryLinkCard(
                icon: Icons.insights_rounded,
                title: 'Báo cáo chi tiết',
                subtitle: 'Kỹ năng và tiến độ',
                onTap: () => context.go('/progress'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryLinkCard(
                icon: Icons.bookmark_rounded,
                title: 'Từ đã lưu',
                subtitle: 'Ôn bộ sưu tập riêng',
                onTap: () => context.go('/bookmark'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ─── Recent Quizzes ────────────────────────────
        Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Quiz gần đây',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.luxuryEspresso,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.luxuryBrown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${recentQuizzes.length}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryBrown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentQuizzes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.luxurySurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.luxuryBrown.withValues(alpha: 0.08),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có bài quiz nào',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.luxuryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Làm quiz đầu tiên để bắt đầu',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.luxuryTextHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.luxuryBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Làm quiz ngay',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentQuizzes.take(4).map((item) => _QuizHistoryTile(item: item)),
      ],
    );
  }
}

class _ProfileActivitySummary extends StatelessWidget {
  final List<WeeklyActivityDay> days;

  const _ProfileActivitySummary({required this.days});

  @override
  Widget build(BuildContext context) {
    final totalXp = days.fold<int>(0, (sum, day) => sum + day.xp);
    final activeDays = days
        .where((day) => day.xp > 0 || day.learned > 0)
        .length;
    final maxXp = days.fold<int>(1, (max, day) => day.xp > max ? day.xp : max);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NHỊP HỌC 7 NGÀY',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.luxuryBrown,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$activeDays ngày hoạt động · $totalXp XP',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: List.generate(7, (index) {
              final xp = index < days.length ? days[index].xp : 0;
              final intensity = (xp / maxXp).clamp(0.0, 1.0);
              return Container(
                width: 17,
                height: 17,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    AppColors.luxuryBorder,
                    AppColors.luxuryBrown,
                    intensity,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SummaryLinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SummaryLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.luxurySurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.luxuryBrown.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.luxuryBrown, size: 21),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.luxuryEspresso,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: AppColors.luxuryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoGradientCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final List<Color> colors;
  const _BentoGradientCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB 2: TIẾN ĐỘ
// ═════════════════════════════════════════════════════════════════════════

class _ProgressTab extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final DashboardStats stats;
  final List<QuizResult> recentQuizzes;
  final List<WeeklyActivityDay> weeklyActivity;
  final List<TopicProgressItem> topics;

  const _ProgressTab({
    required this.isLoading,
    required this.errorMessage,
    required this.stats,
    required this.recentQuizzes,
    required this.weeklyActivity,
    required this.topics,
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
    final mastered = topics.fold<int>(0, (sum, topic) => sum + topic.mastered);
    final totalTopicWords = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.total,
    );
    final retention = totalTopicWords == 0
        ? 0
        : ((mastered / totalTopicWords) * 100).round();
    final quizAverage = recentQuizzes.isEmpty
        ? 0
        : recentQuizzes
                  .take(3)
                  .fold<double>(0, (sum, quiz) => sum + quiz.scorePercent) /
              recentQuizzes.take(3).length;
    final strength = retention >= quizAverage
        ? 'Ghi nhớ từ vựng'
        : 'Phản xạ Quiz';
    final improvement = retention < quizAverage
        ? 'Ôn lại từ sắp quên'
        : 'Luyện Quiz theo ngữ cảnh';

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 760 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.65,
          children: [
            _CompactStatCard(
              label: 'Từ đã học',
              value: '${stats.vocabCount}',
              icon: Icons.menu_book_rounded,
            ),
            _CompactStatCard(
              label: 'Thành thạo',
              value: '$mastered',
              icon: Icons.workspace_premium_rounded,
            ),
            _CompactStatCard(
              label: 'Tỷ lệ nhớ',
              value: '$retention%',
              icon: Icons.psychology_alt_rounded,
            ),
            _CompactStatCard(
              label: 'Quiz đã làm',
              value: '${stats.quizCount}',
              icon: Icons.quiz_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _InsightCard(
                eyebrow: 'ĐIỂM MẠNH',
                title: strength,
                icon: Icons.bolt_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InsightCard(
                eyebrow: 'CẦN CẢI THIỆN',
                title: improvement,
                icon: Icons.track_changes_rounded,
                color: AppColors.luxuryBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ActivityChart(days: weeklyActivity),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text('📚', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'Chủ đề nổi bật',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.luxuryEspresso,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.luxuryBrown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${topics.length}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryBrown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...topics.take(6).map((t) => _TopicTile(item: t)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/progress'),
            icon: const Icon(Icons.insights_rounded),
            label: const Text('Xem báo cáo tiến độ chi tiết'),
          ),
        ),
      ],
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CompactStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.luxuryBrown),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: AppColors.luxuryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 8,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final List<WeeklyActivityDay> days;
  const _ActivityChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final byWeekday = <int, WeeklyActivityDay>{};
    for (final day in days) {
      final date = DateTime.tryParse(day.date);
      if (date != null) byWeekday[date.weekday] = day;
    }
    final display = List.generate(
      7,
      (index) =>
          byWeekday[index + 1] ??
          WeeklyActivityDay(date: '', xp: 0, quizzes: 0, learned: 0),
    );
    final maxXp = display.fold<int>(1, (m, d) => d.xp > m ? d.xp : m);
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.luxuryBrown.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.luxuryBrown,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Hoạt động 7 ngày',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.luxuryEspresso,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day = display[i];
                final h = maxXp == 0 ? 6.0 : 8 + (day.xp / maxXp) * 90;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // ponytail: bar only, removed XP label to fix overflow
                        Container(
                          height: h.clamp(4.0, 110.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.luxuryBrown.withValues(alpha: 0.6),
                                AppColors.luxuryBrown,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i],
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.luxuryText,
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
}

class _TopicTile extends StatelessWidget {
  final TopicProgressItem item;
  const _TopicTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final pct = item.masteryPercent.round();
    final color = pct >= 80
        ? AppColors.luxuryGreen
        : pct >= 40
        ? AppColors.luxuryGold
        : AppColors.luxuryBrown;
    final topicName = item.topic.trim();
    final displayName = topicName.isEmpty
        ? 'Chủ đề chưa đặt tên'
        : '${topicName[0].toUpperCase()}${topicName.substring(1)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: item.masteryPercent / 100,
                  strokeWidth: 4,
                  backgroundColor: AppColors.luxuryBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Text(
                    '$pct%',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
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
                Text(
                  displayName,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.mastered}/${item.total} từ đã nắm vững',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.luxuryText,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.luxuryTextHint, size: 18),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB 3: HUY HIỆU
// ═════════════════════════════════════════════════════════════════════════

class _AllBadges {
  static const all = <_BadgeDef>[
    _BadgeDef('🔥', '7 Ngày Liên Tiếp', 'Đạt streak 7 ngày', 'streak_7'),
    _BadgeDef('🔥', '14 Ngày Liên Tiếp', 'Đạt streak 14 ngày', 'streak_14'),
    _BadgeDef('🏅', '30 Ngày Kiên Trì', 'Đạt streak 30 ngày', 'streak_30'),
    _BadgeDef('💪', '60 Ngày Bền Bỉ', 'Đạt streak 60 ngày', 'streak_60'),
    _BadgeDef(
      '👑',
      '100 Ngày Huyền Thoại',
      'Đạt streak 100 ngày',
      'streak_100',
    ),
    _BadgeDef('🌱', 'Bắt Đầu', 'Thêm từ vựng đầu tiên', 'first_word'),
    _BadgeDef('📚', '50 Từ Vựng', 'Đã thêm 50 từ', 'word_50'),
    _BadgeDef('📖', '100 Từ Vựng', 'Đã học 100 từ', 'word_100'),
    _BadgeDef('📮', '500 Từ Vựng', 'Đã học 500 từ', 'word_500'),
    _BadgeDef('🗺️', '1000 Từ Vựng', 'Tem hiếm cho nhà sưu tầm', 'word_1000'),
    _BadgeDef('🎯', 'Hoàn Hảo', 'Quiz đạt 100%', 'perfect_quiz'),
    _BadgeDef(
      '💌',
      'Bưu Kiện Hoàn Hảo',
      'Mini Test đạt 100%',
      'perfect_mini_test',
    ),
    _BadgeDef('🎮', '10 Quiz', 'Đã làm 10 bài quiz', 'quiz_10'),
    _BadgeDef('🦉', 'Cú Đêm', 'Học sau 10 giờ tối', 'night_owl'),
  ];
}

class _BadgeDef {
  final String icon, title, description, key;
  const _BadgeDef(this.icon, this.title, this.description, this.key);
}

class _BadgeTab extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<AchievementItem> achievements;
  final DashboardStats stats;
  final RewardSummary rewardSummary;
  final List<RewardItem> rewards;
  final List<RewardTransactionItem> rewardHistory;
  final bool isClaiming;

  const _BadgeTab({
    required this.isLoading,
    required this.errorMessage,
    required this.achievements,
    required this.stats,
    required this.rewardSummary,
    required this.rewards,
    required this.rewardHistory,
    required this.isClaiming,
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

    final unlockedKeys = achievements.map((a) => a.achievementKey).toSet();
    final haveAny = achievements.isNotEmpty;
    final nextBadge = _nextBadge(unlockedKeys);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _RewardInboxCard(
          summary: rewardSummary,
          rewards: rewards.where((reward) => reward.isClaimable).toList(),
          isClaiming: isClaiming,
          onClaim: (rewardId) async {
            final messenger = ScaffoldMessenger.of(context);
            final message = await context.read<ProfileProvider>().claimReward(
              rewardId,
            );
            if (!context.mounted || message == null) return;
            messenger.showSnackBar(SnackBar(content: Text(message)));
            await context.read<DashboardProvider>().loadDashboard();
          },
          onClaimAll: () async {
            final messenger = ScaffoldMessenger.of(context);
            final message = await context
                .read<ProfileProvider>()
                .claimAllRewards();
            if (!context.mounted || message == null) return;
            messenger.showSnackBar(SnackBar(content: Text(message)));
            await context.read<DashboardProvider>().loadDashboard();
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.luxuryEspresso,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHẶNG TEM TIẾP THEO',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 9,
                  letterSpacing: 1.3,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nextBadge.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: nextBadge.progress,
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.luxuryGold,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                nextBadge.caption,
                style: GoogleFonts.nunito(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (haveAny)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.luxuryBrown.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.luxuryGold.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.luxuryBrown.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${achievements.length}/${_AllBadges.all.length} huy hiệu',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.luxuryEspresso,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: achievements.length / _AllBadges.all.length,
                          minHeight: 8,
                          backgroundColor: AppColors.luxuryBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.luxuryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (!haveAny) const SizedBox(height: 8),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: _AllBadges.all.length,
          itemBuilder: (_, i) {
            final badge = _AllBadges.all[i];
            final isUnlocked = unlockedKeys.contains(badge.key);
            final ach = isUnlocked
                ? achievements.firstWhere((a) => a.achievementKey == badge.key)
                : null;
            return _BadgeCard(
              icon: badge.icon,
              title: badge.title,
              desc: badge.description,
              unlocked: isUnlocked,
              date: ach?.unlockedAt,
            );
          },
        ),
        if (rewardHistory.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            'Lịch sử phần thưởng',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.luxuryEspresso,
            ),
          ),
          const SizedBox(height: 10),
          ...rewardHistory
              .take(8)
              .map(
                (transaction) => _RewardHistoryTile(transaction: transaction),
              ),
        ],
      ],
    );
  }

  ({String title, String caption, double progress}) _nextBadge(
    Set<String> unlockedKeys,
  ) {
    if (!unlockedKeys.contains('streak_7')) {
      return (
        title: 'Tem Lửa 7 Ngày',
        caption: '${stats.streak}/7 ngày liên tiếp',
        progress: (stats.streak / 7).clamp(0.0, 1.0),
      );
    }
    if (!unlockedKeys.contains('word_50')) {
      return (
        title: 'Tem Nhà Sưu Tầm',
        caption: '${stats.vocabCount}/50 từ đã học',
        progress: (stats.vocabCount / 50).clamp(0.0, 1.0),
      );
    }
    if (!unlockedKeys.contains('word_100')) {
      return (
        title: 'Tem 100 Từ Vựng',
        caption: '${stats.vocabCount}/100 từ đã học',
        progress: (stats.vocabCount / 100).clamp(0.0, 1.0),
      );
    }
    if (!unlockedKeys.contains('word_500')) {
      return (
        title: 'Tem Bưu Điện 500 Từ',
        caption: '${stats.vocabCount}/500 từ đã học',
        progress: (stats.vocabCount / 500).clamp(0.0, 1.0),
      );
    }
    if (!unlockedKeys.contains('quiz_10')) {
      return (
        title: 'Tem Chuyên Gia Quiz',
        caption: '${stats.quizCount}/10 bài quiz',
        progress: (stats.quizCount / 10).clamp(0.0, 1.0),
      );
    }
    return (
      title: 'Tem Huyền Thoại 100 Ngày',
      caption: '${stats.streak}/100 ngày liên tiếp',
      progress: (stats.streak / 100).clamp(0.0, 1.0),
    );
  }
}

class _RewardInboxCard extends StatelessWidget {
  final RewardSummary summary;
  final List<RewardItem> rewards;
  final bool isClaiming;
  final ValueChanged<String> onClaim;
  final VoidCallback onClaimAll;

  const _RewardInboxCard({
    required this.summary,
    required this.rewards,
    required this.isClaiming,
    required this.onClaim,
    required this.onClaimAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.luxuryBrown, AppColors.luxuryBrownLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.luxuryBrown.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HỘP QUÀ',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 9,
                        letterSpacing: 1.3,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      summary.claimableCount > 0
                          ? '${summary.claimableCount} phần thưởng chờ nhận'
                          : 'Chưa có phần thưởng mới',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${summary.gemsBalance} 💎',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${summary.xpTotal} XP',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (rewards.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Hoàn thành streak, Quiz, Mini Test và các chặng CEFR để mở thêm tem thưởng.',
              style: GoogleFonts.nunito(
                fontSize: 12,
                height: 1.4,
                color: Colors.white70,
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ...rewards
                .take(3)
                .map(
                  (reward) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_post_office_outlined,
                          size: 20,
                          color: AppColors.luxuryGold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '+${reward.xpAmount} XP · +${reward.gemsAmount} ngọc',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 9,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: isClaiming
                              ? null
                              : () => onClaim(reward.id),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.luxuryGold,
                          ),
                          child: const Text('Nhận'),
                        ),
                      ],
                    ),
                  ),
                ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isClaiming ? null : onClaimAll,
                icon: isClaiming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.luxuryEspresso,
                        ),
                      )
                    : const Icon(Icons.done_all_rounded, size: 18),
                label: Text(isClaiming ? 'Đang nhận...' : 'Nhận tất cả'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.luxuryGold,
                  foregroundColor: AppColors.luxuryEspresso,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardHistoryTile extends StatelessWidget {
  final RewardTransactionItem transaction;

  const _RewardHistoryTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final date = transaction.createdAt;
    final dateLabel = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.luxuryBrown.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: AppColors.luxuryBrown,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'Phần thưởng học tập',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
                if (dateLabel.isNotEmpty)
                  Text(
                    dateLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: AppColors.luxuryTextHint,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '+${transaction.xpDelta} XP\n+${transaction.gemsDelta} 💎',
            textAlign: TextAlign.right,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 10,
              height: 1.5,
              fontWeight: FontWeight.w700,
              color: AppColors.luxuryBrown,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String icon, title, desc;
  final bool unlocked;
  final DateTime? date;
  const _BadgeCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.unlocked,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: unlocked
              ? AppColors.luxuryGold.withValues(alpha: 0.20)
              : AppColors.luxuryBrown.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.luxuryBrown.withValues(alpha: 0.06)
                  : AppColors.luxuryBorder,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 22,
                  color: unlocked ? null : AppColors.luxuryTextHint,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: unlocked ? AppColors.luxuryEspresso : AppColors.luxuryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unlocked && date != null
                ? 'Mở khóa: ${date!.day}/${date!.month}/${date!.year}'
                : desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: unlocked ? AppColors.luxuryGold : AppColors.luxuryTextHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// TAB 4: TÀI KHOẢN
// ═════════════════════════════════════════════════════════════════════════

class _AccountTab extends StatelessWidget {
  final String email, username;
  final String? englishLevel;
  final UserProfile? profile;
  final VoidCallback onEdit;
  const _AccountTab({
    required this.email,
    required this.username,
    this.englishLevel,
    required this.profile,
    required this.onEdit,
  });

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất khỏi SolVocab?'),
        content: const Text(
          'Tiến độ đã đồng bộ sẽ vẫn được lưu trong tài khoản.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _AccountSectionLabel('HỒ SƠ CÁ NHÂN'),
        _AccTile(
          icon: Icons.person_outline,
          title: 'Tên hiển thị',
          sub: username,
          onTap: onEdit,
        ),
        const SizedBox(height: 8),
        _AccTile(icon: Icons.mail_outline, title: 'Email', sub: email),
        const SizedBox(height: 8),
        _AccTile(
          icon: Icons.school_outlined,
          title: 'Trình độ tiếng Anh',
          sub: getEnglishLevelLabel(englishLevel) ?? 'Chưa chọn',
          onTap: () => _showLevelPicker(context),
        ),
        const SizedBox(height: 8),
        _DailyGoalTile(),
        const SizedBox(height: 18),
        _AccountSectionLabel('THÓI QUEN HỌC'),
        _LearningPreferencesCard(profile: profile),
        const SizedBox(height: 8),
        _AccTile(
          icon: Icons.palette_outlined,
          title: 'Giao diện',
          sub: 'Tem thư cổ điển · đang sử dụng',
        ),
        const SizedBox(height: 18),
        _AccountSectionLabel('DỮ LIỆU & BẢO MẬT'),
        _AccTile(
          icon: Icons.insights_rounded,
          title: 'Báo cáo tiến độ',
          sub: 'Xem phân tích học tập chi tiết',
          onTap: () => context.go('/progress'),
        ),
        const SizedBox(height: 8),
        _AccTile(
          icon: Icons.bookmark_rounded,
          title: 'Từ đã lưu',
          sub: 'Bộ sưu tập từ vựng',
          onTap: () => context.go('/bookmark'),
        ),
        const SizedBox(height: 8),
        _AccTile(
          icon: Icons.lock_reset_rounded,
          title: 'Đổi mật khẩu',
          sub: 'Cập nhật mật khẩu đăng nhập',
          onTap: () => _showPasswordSheet(context),
        ),
        const SizedBox(height: 18),
        _AccountSectionLabel('HỖ TRỢ'),
        _AccTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Gửi phản hồi',
          sub: 'Chia sẻ góp ý để SolVocab tốt hơn',
          onTap: () => _showSupportDialog(context),
        ),
        const SizedBox(height: 8),
        const _AccTile(
          icon: Icons.info_outline_rounded,
          title: 'Giới thiệu SolVocab',
          sub: 'Phiên bản 1.0.0 · Airmail Edition',
        ),
        const SizedBox(height: 18),
        _AccTile(
          icon: Icons.logout_rounded,
          title: 'Đăng xuất',
          sub: 'Kết thúc phiên đăng nhập',
          danger: true,
          onTap: () => _confirmLogout(context),
        ),
        const SizedBox(height: 8),
        _AccTile(
          icon: Icons.delete_forever_outlined,
          title: 'Xóa tài khoản',
          sub: 'Yêu cầu hỗ trợ xóa dữ liệu vĩnh viễn',
          danger: true,
          onTap: () => _showDeleteAccountInfo(context),
        ),
      ],
    );
  }

  Future<void> _showPasswordSheet(BuildContext context) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đổi mật khẩu',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final error = await context
                      .read<AuthProvider>()
                      .updatePassword(controller.text);
                  if (!sheetContext.mounted) return;
                  if (error == null) Navigator.pop(sheetContext);
                  messenger.showSnackBar(
                    SnackBar(content: Text(error ?? 'Đã cập nhật mật khẩu.')),
                  );
                },
                child: const Text('Cập nhật mật khẩu'),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  void _showSupportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gửi phản hồi'),
        content: const Text(
          'Bạn có thể gửi góp ý qua email hỗ trợ: support@solvocab.app',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text(
          'Để tránh xóa nhầm dữ liệu học tập, yêu cầu xóa tài khoản cần được xác nhận qua email hỗ trợ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _AccountSectionLabel extends StatelessWidget {
  final String label;

  const _AccountSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 9,
          letterSpacing: 1.25,
          fontWeight: FontWeight.w700,
          color: AppColors.luxuryBrown,
        ),
      ),
    );
  }
}

class _LearningPreferencesCard extends StatefulWidget {
  final UserProfile? profile;

  const _LearningPreferencesCard({required this.profile});

  @override
  State<_LearningPreferencesCard> createState() =>
      _LearningPreferencesCardState();
}

class _LearningPreferencesCardState extends State<_LearningPreferencesCard> {
  double? _minutes;

  @override
  Widget build(BuildContext context) {
    final goals = widget.profile?.learningGoals ?? const <String, dynamic>{};
    final savedMinutes = (goals['daily_minutes'] as num?)?.toDouble() ?? 15;
    final minutes = _minutes ?? savedMinutes;
    final dailyReminder = goals['daily_reminder'] as bool? ?? true;
    final reviewReminder = goals['review_reminder'] as bool? ?? true;
    final preferredMode = goals['preferred_mode'] as String? ?? 'flashcard';
    final provider = context.read<ProfileProvider>();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 19,
                color: AppColors.luxuryBrown,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mục tiêu ${minutes.round()} phút mỗi ngày',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: minutes,
            min: 5,
            max: 60,
            divisions: 11,
            label: '${minutes.round()} phút',
            onChanged: (value) => setState(() => _minutes = value),
            onChangeEnd: (value) async {
              await provider.updateLearningPreferences({
                'daily_minutes': value.round(),
              });
              if (mounted) setState(() => _minutes = null);
            },
          ),
          const Divider(height: 20),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nhắc học hằng ngày'),
            subtitle: const Text('Giữ nhịp học và streak'),
            value: dailyReminder,
            onChanged: (value) =>
                provider.updateLearningPreferences({'daily_reminder': value}),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nhắc ôn từ sắp quên'),
            subtitle: const Text('Theo lịch spaced repetition'),
            value: reviewReminder,
            onChanged: (value) =>
                provider.updateLearningPreferences({'review_reminder': value}),
          ),
          const SizedBox(height: 8),
          Text(
            'MỞ APP VỚI',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 9,
              letterSpacing: 1.1,
              color: AppColors.luxuryText,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'flashcard',
                label: Text('Flashcard'),
                icon: Icon(Icons.style_rounded),
              ),
              ButtonSegment(
                value: 'quiz',
                label: Text('Quiz'),
                icon: Icon(Icons.quiz_outlined),
              ),
            ],
            selected: {preferredMode},
            onSelectionChanged: (selection) => provider
                .updateLearningPreferences({'preferred_mode': selection.first}),
          ),
        ],
      ),
    );
  }
}

class _AccTile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback? onTap;
  final bool danger;
  const _AccTile({
    required this.icon,
    required this.title,
    required this.sub,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: danger
                        ? AppColors.luxuryDanger.withValues(alpha: 0.08)
                        : AppColors.luxuryBrown.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: danger
                        ? AppColors.luxuryDanger
                        : AppColors.luxuryBrown,
                    size: 18,
                  ),
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
                          fontWeight: FontWeight.w700,
                          color: danger
                              ? AppColors.luxuryDanger
                              : AppColors.luxuryEspresso,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.luxuryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null && !danger)
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.luxuryTextHint,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyGoalTile extends StatefulWidget {
  @override
  State<_DailyGoalTile> createState() => _DailyGoalTileState();
}

class _DailyGoalTileState extends State<_DailyGoalTile> {
  double? _draftGoal;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final savedGoal = profile.userProfile?.dailyWordGoal ?? 10;
        final goal = _draftGoal ?? savedGoal.toDouble();
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.luxurySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.luxuryBrown.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.luxuryBrown.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.flag_outlined,
                      color: AppColors.luxuryBrown,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Mục tiêu từ mới mỗi ngày',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.luxuryEspresso,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '5',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.luxuryText,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                        activeTrackColor: AppColors.luxuryBrown,
                        inactiveTrackColor: AppColors.luxuryBorder,
                        thumbColor: AppColors.luxuryBrown,
                        overlayColor: AppColors.luxuryBrown.withValues(
                          alpha: 0.12,
                        ),
                      ),
                      child: Slider(
                        value: goal,
                        min: 5,
                        max: 50,
                        divisions: 9,
                        label: '${goal.round()} từ',
                        onChanged: (value) =>
                            setState(() => _draftGoal = value),
                        onChangeEnd: (value) async {
                          await profile.updateDailyGoal(value.round());
                          if (mounted) setState(() => _draftGoal = null);
                        },
                      ),
                    ),
                  ),
                  Text(
                    '50',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.luxuryText,
                    ),
                  ),
                ],
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.luxuryBrown.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${goal.round()} từ / ngày',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.luxuryBrown,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// SHARED — Quiz History Tile
// ═════════════════════════════════════════════════════════════════════════

class _QuizHistoryTile extends StatelessWidget {
  final QuizResult item;
  const _QuizHistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final score = item.scorePercent.round();
    final color = score >= 80
        ? AppColors.luxuryGreen
        : score >= 50
        ? AppColors.luxuryGold
        : AppColors.luxuryDanger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.luxurySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.luxuryBrown.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 3.5,
                  backgroundColor: AppColors.luxuryBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Text(
                    '$score%',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
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
                Text(
                  item.topic?.isNotEmpty == true
                      ? 'Quiz chủ đề ${item.topic}'
                      : item.quizType,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.luxuryEspresso,
                  ),
                ),
                Text(
                  '${item.correctAnswers}/${item.totalQuestions} câu đúng',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.luxuryText,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.luxuryTextHint, size: 18),
        ],
      ),
    );
  }
}
