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
      vsync: this, duration: const Duration(milliseconds: 900),
    );
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: const Interval(0, 0.5, curve: _spring));
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: const Interval(0, 0.5, curve: _spring)));

    // Content entrance — fades in after hero
    _contentCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: const Interval(0, 1, curve: _slide));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _heroCtrl.forward().then((_) => _contentCtrl.forward());
      final dashboard = context.read<DashboardProvider>();
      final profile = context.read<ProfileProvider>();
      if (dashboard.data == null && !dashboard.isLoading) dashboard.loadDashboard();
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
    final displayName = (metadata?['username'] as String?)?.trim();
    final fallbackName = email.contains('@') ? email.split('@').first : 'Học viên';
    final username = displayName?.isNotEmpty == true ? displayName! : fallbackName;
    final avatarText = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final stats = dashboard.data?.stats ?? DashboardStats();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF8B6F5E),
          onRefresh: () async {
            await dashboard.loadDashboard();
            await profile.loadProfile();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // ─── EDITORIAL LUXURY HERO ────────────────────
              FadeTransition(
                opacity: _heroFade,
                child: SlideTransition(
                  position: _heroSlide,
                  child: _buildHeroBento(
                    avatarText, username, email, stats,
                    profile.userProfile?.englishLevel,
                    profile.isClaimingReward ? null : () async {
                      final msg = await profile.claimStreakReward();
                      if (!mounted || msg == null) return;
                      await dashboard.loadDashboard();
                    },
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ─── GLASS TAB BAR (fades in later) ────────
              FadeTransition(
                opacity: _contentFade,
                child: _buildGlassTabBar(),
              ),

              const SizedBox(height: 20),

              // ─── TAB CONTENT ───────────────────────────
              FadeTransition(
                opacity: _contentFade,
                child: SizedBox(
                  height: 740,
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // HERO — Editorial Luxury Bento
  // Double-Bezel outer shell · Cream gradient · Glass orbs
  // ═════════════════════════════════════════════════════════════════════

  Widget _buildHeroBento(
    String avatarText, String username, String email,
    DashboardStats stats, String? englishLevel, VoidCallback? onClaimReward,
  ) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: const Color(0xFF8B6F5E).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.08)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFDF8F3),
              const Color(0xFFF5EDE4),
              const Color(0xFFEDE0D4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B6F5E).withValues(alpha: 0.08),
              blurRadius: 40, offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: const Color(0xFF8B6F5E).withValues(alpha: 0.04),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ─── Decorative glass orbs ──────────────────
            Positioned(
              top: -60, right: -40,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC4A88B).withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30, left: -30,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4BFA5).withValues(alpha: 0.05),
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
                      // Double-Bezel avatar
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: const [Color(0xFFC4A88B), Color(0xFF8B6F5E)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: const Color(0xFFFDFBF7),
                          child: Text(
                            avatarText,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 30, fontWeight: FontWeight.w700,
                              color: const Color(0xFF5C4A3A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26, fontWeight: FontWeight.w700,
                                color: const Color(0xFF3D3028), height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email,
                              style: GoogleFonts.nunito(
                                fontSize: 13, color: const Color(0xFF8B7B6E),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _EnglishLevelBadge(
                              level: englishLevel,
                              onTap: () => _showLevelPicker(context),
                            ),
                          ],
                        ),
                      ),
                      // Edit — Double-Bezel button
                      GestureDetector(
                        onTap: () => _showEditProfileSheet(username),
                        child: Container(
                          padding: const EdgeInsets.all(1.2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B6F5E).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.10)),
                          ),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFBF7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: const Color(0xFF8B6F5E),
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
                      Expanded(flex: 6, child: _statBentoCard(
                        value: stats.level, label: 'Cấp độ',
                        icon: Icons.auto_awesome_rounded,
                        gradientColors: const [Color(0xFF8B6F5E), Color(0xFFA88B72)],
                      )),
                      const SizedBox(width: 10),
                      // XP — (flex: 5)
                      Expanded(flex: 5, child: _statBentoCard(
                        value: stats.xp, label: 'XP',
                        icon: Icons.trending_up_rounded,
                        gradientColors: const [Color(0xFFC4A88B), Color(0xFF8B6F5E)],
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _statBentoCard(
                        value: stats.streak, label: 'Streak ngày',
                        icon: Icons.local_fire_department_rounded,
                        gradientColors: const [Color(0xFFD4BFA5), Color(0xFFC4A88B)],
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _statBentoCard(
                        value: stats.gems, label: 'Ngọc',
                        icon: Icons.diamond_rounded,
                        gradientColors: const [Color(0xFF8B6F5E), Color(0xFF6B5A4A)],
                      )),
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
                          label: 'Nhận thưởng',
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.20),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(height: 14),
          Text('$value',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
            style: GoogleFonts.nunito(
              fontSize: 12, fontWeight: FontWeight.w600,
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
        color: const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B6F5E).withValues(alpha: 0.04),
            blurRadius: 16, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF8B7B6E),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Color(0xFF8B6F5E), Color(0xFFA88B72)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B6F5E).withValues(alpha: 0.30),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Tiến độ'),
          Tab(text: 'Huy hiệu'),
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
          padding: EdgeInsets.fromLTRB(28, 24, 28, 28 + MediaQuery.of(ctx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44, height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B6F5E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Cập nhật tên hiển thị',
                  style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF3D3028))),
              const SizedBox(height: 6),
              Text('Tên này được hiển thị trên hồ sơ và bảng xếp hạng',
                  style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF8B7B6E))),
              const SizedBox(height: 22),
              // Double-Bezel input
              Container(
                padding: const EdgeInsets.all(1.2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6F5E).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.08)),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: controller,
                    style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF3D3028)),
                    decoration: InputDecoration(
                      labelText: 'Tên hiển thị',
                      labelStyle: GoogleFonts.nunito(color: const Color(0xFF8B7B6E), fontSize: 13),
                      prefixIcon: Icon(Icons.person_outline, color: const Color(0xFF8B7B6E), size: 20),
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
                      colors: [Color(0xFF8B6F5E), Color(0xFFA88B72)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B6F5E).withValues(alpha: 0.25),
                        blurRadius: 16, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(ctx);
                      final navigator = Navigator.of(ctx);
                      final error = await profile.updateDisplayName(controller.text);
                      if (!mounted) return;
                      if (error != null) {
                        messenger.showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }
                      authProv.setUser(authProv.user);
                      navigator.pop();
                      messenger.showSnackBar(const SnackBar(content: Text('✅ Đã cập nhật tên hiển thị.')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Lưu thay đổi',
                              style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(width: 10),
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
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

// ═════════════════════════════════════════════════════════════════════════
// ENGLISH LEVEL BADGE — editorial chip
// ═════════════════════════════════════════════════════════════════════════

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF8B6F5E).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(label ?? 'Chưa xác định',
                style: GoogleFonts.nunito(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C4A3A),
                )),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 10, color: const Color(0xFF8B7B6E).withValues(alpha: 0.60)),
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
    required this.label, required this.icon,
    required this.onTap, this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.transparent : const Color(0xFFFDFBF7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: outlined
                ? Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.20))
                : null,
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF8B6F5E).withValues(alpha: 0.06),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: outlined
                  ? const Color(0xFF8B6F5E)
                  : const Color(0xFF5C4A3A)),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: outlined
                        ? const Color(0xFF8B6F5E)
                        : const Color(0xFF5C4A3A),
                  )),
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
  final currentLevel = profile.userProfile?.englishLevel;
  final messenger = ScaffoldMessenger.of(context);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44, height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6F5E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Chọn trình độ tiếng Anh',
                style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF3D3028))),
            const SizedBox(height: 6),
            Text('Giúp chúng tôi gợi ý nội dung phù hợp với bạn.',
                style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF8B7B6E))),
            const SizedBox(height: 18),
            ...englishLevels.map((level) {
              final isSelected = level['key'] == currentLevel;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () async {
                    final error = await profile.updateEnglishLevel(level['key']!);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (!context.mounted) return;
                    messenger.showSnackBar(SnackBar(
                      backgroundColor: error != null ? AppColors.danger : const Color(0xFF8B6F5E),
                      content: Text(error ?? '✅ Đã cập nhật trình độ: ${level['label']}'),
                    ));
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B6F5E).withValues(alpha: 0.06)
                          : const Color(0xFFFFFCF9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF8B6F5E) : const Color(0xFF8B6F5E).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(level['emoji']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(level['label']!,
                              style: GoogleFonts.nunito(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: const Color(0xFF3D3028),
                              )),
                        ),
                        if (isSelected)
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B6F5E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 14, color: Colors.white),
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
// TAB 1: TỔNG QUAN — Asymmetrical Bento Grid + Editorial Card
// ═════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final DashboardStats stats;
  final List<QuizResult> recentQuizzes;
  const _OverviewTab({required this.stats, required this.recentQuizzes});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        // ─── Asymmetrical Bento ──────────────────────
        Row(
          children: [
            Expanded(flex: 7, child: _BentoGradientCard(
              value: '${stats.vocabCount}', label: 'Từ đã học',
              icon: Icons.menu_book_rounded,
              colors: const [Color(0xFF8B6F5E), Color(0xFFA88B72)],
            )),
            const SizedBox(width: 10),
            Expanded(flex: 5, child: _BentoGradientCard(
              value: '${stats.accuracyRate.round()}%', label: 'Độ chính xác',
              icon: Icons.track_changes_rounded,
              colors: const [Color(0xFFC4A88B), Color(0xFF8B6F5E)],
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _BentoGradientCard(
              value: '${stats.quizCount}', label: 'Quiz đã làm',
              icon: Icons.quiz_rounded,
              colors: const [Color(0xFFD4BFA5), Color(0xFFC4A88B)],
            )),
            const SizedBox(width: 10),
            Expanded(child: _BentoGradientCard(
              value: '${stats.weeklyProgress}%', label: 'Tiến độ tuần',
              icon: Icons.timelapse_rounded,
              colors: const [Color(0xFF8B6F5E), Color(0xFF6B5A4A)],
            )),
          ],
        ),

        const SizedBox(height: 24),

        // ─── Recent Quizzes ────────────────────────────
        Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('Quiz gần đây',
                style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF3D3028))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B6F5E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${recentQuizzes.length}',
                  style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF8B6F5E))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentQuizzes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.08)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text('Chưa có bài quiz nào',
                      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF8B7B6E))),
                  const SizedBox(height: 4),
                  Text('Làm quiz đầu tiên để bắt đầu',
                      style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFFB0A090))),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6F5E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: Text('Làm quiz ngay',
                          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700)),
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

class _BentoGradientCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final List<Color> colors;
  const _BentoGradientCard({
    required this.value, required this.label,
    required this.icon, required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.20),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white,
                height: 1.05,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.nunito(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.85),
              )),
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
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _ActivityChart(days: weeklyActivity),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text('📚', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('Chủ đề nổi bật',
                style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF3D3028))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B6F5E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${topics.length}',
                  style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF8B6F5E))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...topics.take(6).map((t) => _TopicTile(item: t)),
      ],
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final List<WeeklyActivityDay> days;
  const _ActivityChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final display = days.isEmpty
        ? List.generate(7, (_) => WeeklyActivityDay(date: '', xp: 0, quizzes: 0, learned: 0))
        : days;
    final maxXp = display.fold<int>(1, (m, d) => d.xp > m ? d.xp : m);
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B6F5E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insights_rounded, color: Color(0xFF8B6F5E), size: 16),
            ),
            const SizedBox(width: 10),
            Text('Hoạt động 7 ngày',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF3D3028))),
          ]),
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
                                const Color(0xFF8B6F5E).withValues(alpha: 0.6),
                                const Color(0xFF8B6F5E),
                              ],
                              begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(labels[i],
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B7B6E),
                            )),
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
    final color = pct >= 80 ? const Color(0xFF6BA368) : pct >= 40 ? const Color(0xFFC49A3C) : const Color(0xFF8B6F5E);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          SizedBox(width: 46, height: 46, child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(
              value: item.masteryPercent / 100, strokeWidth: 4,
              backgroundColor: const Color(0xFFEDE0D4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Center(child: Text('$pct%',
                style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w800, color: color))),
          ])),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.topic[0].toUpperCase() + item.topic.substring(1),
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF3D3028))),
            const SizedBox(height: 2),
            Text('${item.mastered}/${item.total} từ đã nắm vững',
                style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF8B7B6E))),
          ])),
          Icon(Icons.chevron_right, color: const Color(0xFFB0A090), size: 18),
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
    _BadgeDef('👑', '100 Ngày Huyền Thoại', 'Đạt streak 100 ngày', 'streak_100'),
    _BadgeDef('🌱', 'Bắt Đầu', 'Thêm từ vựng đầu tiên', 'first_word'),
    _BadgeDef('📚', '50 Từ Vựng', 'Đã thêm 50 từ', 'word_50'),
    _BadgeDef('📖', '200 Từ Vựng', 'Đã thêm 200 từ', 'word_200'),
    _BadgeDef('🎯', 'Hoàn Hảo', 'Quiz đạt 100%', 'perfect_quiz'),
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
  const _BadgeTab({
    required this.isLoading, required this.errorMessage, required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && achievements.isEmpty) return const SkeletonLoading(type: SkeletonType.grid);
    if (errorMessage != null && achievements.isEmpty) {
      return ErrorStateWidget(message: errorMessage!, onRetry: () => context.read<ProfileProvider>().loadProfile());
    }

    final unlockedKeys = achievements.map((a) => a.achievementKey).toSet();
    final haveAny = achievements.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        if (haveAny)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B6F5E).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC49A3C).withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B6F5E).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('🏆', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${achievements.length}/${_AllBadges.all.length} huy hiệu',
                      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF3D3028))),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: achievements.length / _AllBadges.all.length,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEDE0D4),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC49A3C)),
                    ),
                  ),
                ])),
              ],
            ),
          ),
        if (!haveAny) const SizedBox(height: 8),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: _AllBadges.all.length,
          itemBuilder: (_, i) {
            final badge = _AllBadges.all[i];
            final isUnlocked = unlockedKeys.contains(badge.key);
            final ach = isUnlocked ? achievements.firstWhere((a) => a.achievementKey == badge.key) : null;
            return _BadgeCard(
              icon: badge.icon, title: badge.title, desc: badge.description,
              unlocked: isUnlocked, date: ach?.unlockedAt,
            );
          },
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String icon, title, desc;
  final bool unlocked;
  final DateTime? date;
  const _BadgeCard({required this.icon, required this.title, required this.desc, required this.unlocked, this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: unlocked ? const Color(0xFFC49A3C).withValues(alpha: 0.20) : const Color(0xFF8B6F5E).withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: unlocked ? const Color(0xFF8B6F5E).withValues(alpha: 0.06) : const Color(0xFFEDE0D4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(icon, style: TextStyle(
              fontSize: 22, color: unlocked ? null : const Color(0xFFB0A090),
            ))),
          ),
          const Spacer(),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: unlocked ? const Color(0xFF3D3028) : const Color(0xFF8B7B6E),
              )),
          const SizedBox(height: 4),
          Text(unlocked && date != null ? 'Mở khóa: ${date!.day}/${date!.month}/${date!.year}' : desc,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 11, color: unlocked ? const Color(0xFFC49A3C) : const Color(0xFFB0A090),
              )),
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
  final VoidCallback onEdit;
  const _AccountTab({
    required this.email, required this.username, this.englishLevel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _AccTile(icon: Icons.person_outline, title: 'Tên hiển thị', sub: username, onTap: onEdit),
        const SizedBox(height: 8),
        _AccTile(icon: Icons.mail_outline, title: 'Email', sub: email),
        const SizedBox(height: 8),
        _AccTile(icon: Icons.school_outlined, title: 'Trình độ tiếng Anh',
            sub: getEnglishLevelLabel(englishLevel) ?? 'Chưa chọn',
            onTap: () => _showLevelPicker(context)),
        const SizedBox(height: 8),
        _DailyGoalTile(),
        const SizedBox(height: 8),
        _AccTile(icon: Icons.history_rounded, title: 'Lịch sử quiz', sub: 'Xem các bài quiz đã làm',
            onTap: () => context.go('/quiz/history')),
        const SizedBox(height: 8),
        _AccTile(icon: Icons.bookmark_rounded, title: 'Từ đã lưu', sub: 'Bộ sưu tập từ vựng',
            onTap: () => context.go('/bookmark')),
        const SizedBox(height: 16),
        _AccTile(icon: Icons.logout_rounded, title: 'Đăng xuất', sub: 'Kết thúc phiên đăng nhập',
            danger: true, onTap: () => context.read<AuthProvider>().logout()),
      ],
    );
  }
}

class _AccTile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback? onTap;
  final bool danger;
  const _AccTile({required this.icon, required this.title, required this.sub, this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.06)),
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
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: danger ? const Color(0xFFFF6B7A).withValues(alpha: 0.08) : const Color(0xFF8B6F5E).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: danger ? const Color(0xFFFF6B7A) : const Color(0xFF8B6F5E), size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: danger ? const Color(0xFFFF6B7A) : const Color(0xFF3D3028),
                      )),
                  const SizedBox(height: 2),
                  Text(sub, style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF8B7B6E))),
                ])),
                if (onTap != null && !danger)
                  Icon(Icons.chevron_right, color: const Color(0xFFB0A090), size: 18),
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
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final goal = profile.userProfile?.dailyWordGoal ?? 10;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B6F5E).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.flag_outlined, color: Color(0xFF8B6F5E), size: 18),
                ),
                const SizedBox(width: 14),
                Text('Mục tiêu từ mới mỗi ngày',
                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF3D3028))),
              ]),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('5', style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF8B7B6E))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        activeTrackColor: const Color(0xFF8B6F5E),
                        inactiveTrackColor: const Color(0xFFEDE0D4),
                        thumbColor: const Color(0xFF8B6F5E),
                        overlayColor: const Color(0xFF8B6F5E).withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: goal.toDouble(), min: 5, max: 50, divisions: 9,
                        label: '$goal từ',
                        onChanged: (_) {},
                        onChangeEnd: (v) => profile.updateDailyGoal(v.round()),
                      ),
                    ),
                  ),
                  Text('50', style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF8B7B6E))),
                ],
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B6F5E).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$goal từ / ngày',
                      style: GoogleFonts.ibmPlexMono(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF8B6F5E))),
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
    final color = score >= 80 ? const Color(0xFF6BA368) : score >= 50 ? const Color(0xFFC49A3C) : const Color(0xFFFF6B7A);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8B6F5E).withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          SizedBox(width: 46, height: 46, child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(
              value: score / 100, strokeWidth: 3.5,
              backgroundColor: const Color(0xFFEDE0D4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Center(child: Text('$score%',
                style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w800, color: color))),
          ])),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.topic?.isNotEmpty == true ? 'Quiz chủ đề ${item.topic}' : item.quizType,
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF3D3028))),
            Text('${item.correctAnswers}/${item.totalQuestions} câu đúng',
                style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF8B7B6E))),
          ])),
          Icon(Icons.chevron_right, color: const Color(0xFFB0A090), size: 18),
        ],
      ),
    );
  }
}
