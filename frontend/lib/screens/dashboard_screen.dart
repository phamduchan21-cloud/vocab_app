import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/mini_test_questions.dart';
import '../models/dashboard_data.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_logo.dart';
import '../widgets/cat_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/weekly_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboard = context.read<DashboardProvider>();
      final profile = context.read<ProfileProvider>();
      if (dashboard.data == null && !dashboard.isLoading) {
        dashboard.loadDashboard();
      }
      if (profile.userProfile == null && !profile.isLoading) {
        profile.loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final profile = context.watch<ProfileProvider>();
    final auth = context.watch<AuthProvider>();
    final metadataName = auth.user?.userMetadata?['username'] as String?;
    final emailName = auth.user?.email?.split('@').first;
    final displayName =
        profile.userProfile?.username ?? metadataName ?? emailName ?? 'bạn';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 920;
        final content = _DashboardContent(
          dashboard: dashboard,
          profile: profile,
          displayName: displayName,
        );

        if (!isWide) {
          return Scaffold(
            backgroundColor: AppColors.luxuryBg,
            bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
            body: SafeArea(child: content),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.luxuryBg,
          body: Row(
            children: [
              _HomeSidebar(
                displayName: displayName,
                level: dashboard.data?.stats.level ?? 0,
              ),
              Expanded(child: SafeArea(child: content)),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.dashboard,
    required this.profile,
    required this.displayName,
  });

  final DashboardProvider dashboard;
  final ProfileProvider profile;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    if (dashboard.isLoading && dashboard.data == null) {
      return const LoadingWidget(message: 'Đang chuẩn bị lộ trình hôm nay...');
    }
    if (dashboard.errorMessage != null && dashboard.data == null) {
      return ErrorStateWidget(
        message: dashboard.errorMessage!,
        onRetry: dashboard.loadDashboard,
      );
    }

    final data =
        dashboard.data ??
        DashboardData(
          stats: DashboardStats(),
          review: TodayReviewData(),
          topics: const [],
          leaderboard: const [],
        );
    final stats = data.stats;
    final review = data.review;
    final dailyGoal = profile.userProfile?.dailyWordGoal ?? 10;
    final hasQuizToday = _hasQuizToday(stats.recentQuizzes);
    final learnedToday = review.completed.clamp(0, dailyGoal);

    return RefreshIndicator(
      color: const Color(0xFFE95F52),
      onRefresh: () async {
        await Future.wait([dashboard.refresh(), profile.loadProfile()]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopGreeting(displayName: displayName),
                const SizedBox(height: 18),
                _Reveal(
                  child: _DailyDispatchHero(
                    displayName: displayName,
                    stats: stats,
                    review: review,
                    dailyGoal: dailyGoal,
                    learnedToday: learnedToday,
                  ),
                ),
                const SizedBox(height: 28),
                _SectionHeading(
                  eyebrow: 'LỘ TRÌNH NGẮN',
                  title: 'Ba điểm dừng hôm nay',
                  actionLabel: 'Xem tiến độ',
                  onAction: () => context.go('/progress'),
                ),
                const SizedBox(height: 14),
                _Reveal(
                  delayMs: 80,
                  child: _TodayJourney(
                    review: review,
                    hasQuizToday: hasQuizToday,
                    dailyGoal: dailyGoal,
                    learnedToday: learnedToday,
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final sideBySide = constraints.maxWidth >= 820;
                    final recommendation = _RecommendationCard(
                      data: data,
                      profile: profile,
                    );
                    final weekly = WeeklyChart(
                      days: profile.data,
                      currentXp: stats.xp,
                      weeklyXpGoal: 500,
                    );
                    if (!sideBySide) {
                      return Column(
                        children: [
                          recommendation,
                          const SizedBox(height: 16),
                          weekly,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 11, child: recommendation),
                        const SizedBox(width: 16),
                        Expanded(flex: 10, child: weekly),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
                _SectionHeading(
                  eyebrow: 'KHO BƯU THIẾP',
                  title: 'Khám phá theo chủ đề',
                  actionLabel: 'Tất cả chủ đề',
                  onAction: () => context.go('/topics'),
                ),
                const SizedBox(height: 14),
                _TopicPostcards(topics: data.topics),
                const SizedBox(height: 30),
                _RecentActivity(stats: stats),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasQuizToday(List<DashboardQuiz> quizzes) {
    final now = DateTime.now();
    return quizzes.any((quiz) {
      final date = quiz.completedAt?.toLocal();
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    });
  }
}

class _TopGreeting extends StatelessWidget {
  const _TopGreeting({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Chào buổi sáng'
        : hour < 18
        ? 'Chào buổi chiều'
        : 'Chào buổi tối';
    final dayLabels = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final now = DateTime.now();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $displayName',
                style: GoogleFonts.nunito(
                  color: AppColors.luxuryText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${dayLabels[now.weekday - 1]}, ${now.day}/${now.month}',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.luxuryEspresso,
                  fontWeight: FontWeight.w800,
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          tooltip: 'Hồ sơ và cài đặt',
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}

class _DailyDispatchHero extends StatelessWidget {
  const _DailyDispatchHero({
    required this.displayName,
    required this.stats,
    required this.review,
    required this.dailyGoal,
    required this.learnedToday,
  });

  final String displayName;
  final DashboardStats stats;
  final TodayReviewData review;
  final int dailyGoal;
  final int learnedToday;

  @override
  Widget build(BuildContext context) {
    final due = review.remaining.clamp(0, review.total);
    final progress = dailyGoal == 0
        ? 0.0
        : (learnedToday / dailyGoal).clamp(0.0, 1.0);
    final title = due > 0
        ? '$due thẻ đang chờ bạn đóng dấu ôn tập.'
        : 'Hộp thư ôn tập đã gọn. Hãy gửi thêm 5 từ mới.';
    final buttonLabel = due > 0 ? 'Ôn $due thẻ ngay' : 'Học 5 từ mới';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F6862),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2915433F),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            const Positioned.fill(child: _AirmailHeroPattern()),
            Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 660;
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'BƯU KIỆN HỌC TẬP HÔM NAY',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                          fontSize: compact ? 29 : 36,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        due > 0
                            ? 'Ôn đúng lúc giúp từ vựng ở lại lâu hơn trong trí nhớ.'
                            : 'Một phiên ngắn là đủ để giữ nhịp học và streak hôm nay.',
                        style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.45,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => context.go(
                              due > 0
                                  ? '/flashcard'
                                  : '/flashcard?starter=true',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE95F52),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: const Icon(Icons.style_rounded),
                            label: Text(
                              buttonLabel,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/quiz'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.46),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: const Icon(Icons.bolt_rounded),
                            label: const Text('Quiz nhanh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                color: const Color(0xFFF5B940),
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$learnedToday/$dailyGoal từ',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  final stamp = _HeroStamp(stats: stats, progress: progress);
                  if (compact) {
                    return Column(
                      children: [copy, const SizedBox(height: 22), stamp],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 3, child: copy),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: stamp),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStamp extends StatelessWidget {
  const _HeroStamp({required this.stats, required this.progress});

  final DashboardStats stats;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: -0.035,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE95F52), width: 3),
          ),
          child: Row(
            children: [
              const CatWidget(size: 78, expression: CatExpression.happy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.streak} NGÀY',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFFE95F52),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Streak đang bay',
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.luxuryEspresso,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.xp} XP · Cấp ${stats.level}',
                      style: GoogleFonts.nunito(
                        color: AppColors.luxuryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayJourney extends StatelessWidget {
  const _TodayJourney({
    required this.review,
    required this.hasQuizToday,
    required this.dailyGoal,
    required this.learnedToday,
  });

  final TodayReviewData review;
  final bool hasQuizToday;
  final int dailyGoal;
  final int learnedToday;

  @override
  Widget build(BuildContext context) {
    final reviewDone = review.total > 0 && review.remaining <= 0;
    final goalDone = learnedToday >= dailyGoal;
    final cards = [
      _JourneyStep(
        number: '01',
        icon: Icons.style_rounded,
        title: review.remaining > 0
            ? 'Ôn ${review.remaining} thẻ'
            : 'Học từ mới',
        caption: reviewDone ? 'Đã đóng dấu hoàn thành' : 'Lặp lại ngắt quãng',
        done: reviewDone,
        color: const Color(0xFF0D716B),
        onTap: () => context.go('/flashcard'),
      ),
      _JourneyStep(
        number: '02',
        icon: Icons.quiz_outlined,
        title: 'Quiz ghi nhớ',
        caption: hasQuizToday ? 'Đã luyện hôm nay' : '5 phút luyện nhanh',
        done: hasQuizToday,
        color: const Color(0xFFF0A52B),
        onTap: () => context.go('/quiz'),
      ),
      _JourneyStep(
        number: '03',
        icon: Icons.fact_check_outlined,
        title: 'Mini Test',
        caption: goalDone ? 'Mục tiêu ngày đã đạt' : 'Đánh giá toàn diện',
        done: goalDone,
        color: const Color(0xFFE95F52),
        onTap: () => context.go('/mock-test'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ),
                )
                .toList(),
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.caption,
    required this.done,
    required this.color,
    required this.onTap,
  });

  final String number;
  final IconData icon;
  final String title;
  final String caption;
  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.luxurySurface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: done
                  ? const Color(0xFF0D716B).withValues(alpha: 0.38)
                  : AppColors.luxuryBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(done ? Icons.check_rounded : icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number · $title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: AppColors.luxuryEspresso,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: done
                            ? const Color(0xFF0D716B)
                            : AppColors.luxuryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.luxuryTextHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.data, required this.profile});

  final DashboardData data;
  final ProfileProvider profile;

  @override
  Widget build(BuildContext context) {
    final topicKey = MiniTestBank
        .topicKeys[DateTime.now().day % MiniTestBank.topicKeys.length];
    final topicLabel = MiniTestBank.displayName(topicKey) ?? topicKey;
    final recentWord = data.stats.recentVocabs.isEmpty
        ? null
        : data.stats.recentVocabs.first;
    final level = profile.userProfile?.englishLevel;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7C8A9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE95F52),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'GỢI Ý RIÊNG CHO BẠN',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 9,
                  ),
                ),
              ),
              const Spacer(),
              if (level != null)
                Text(
                  level.toUpperCase(),
                  style: GoogleFonts.nunito(
                    color: AppColors.luxuryBrown,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            topicLabel,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.luxuryEspresso,
              fontWeight: FontWeight.w800,
              fontSize: 27,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recentWord == null
                ? 'Một chủ đề vừa sức để mở đầu hành trình hôm nay.'
                : 'Tiếp nối từ “${recentWord.word}” bạn vừa học gần đây.',
            style: GoogleFonts.nunito(
              color: AppColors.luxuryText,
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/topics'),
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Xem chủ đề'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<FlashcardProvider>().setTopic(topicKey);
                    context.go('/flashcard');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D716B),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Học ngay'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicPostcards extends StatelessWidget {
  const _TopicPostcards({required this.topics});

  final List<TopicProgressItem> topics;

  static const _fallback = [
    'greetings',
    'family',
    'food',
    'travel',
    'work',
    'technology',
  ];

  static const _icons = {
    'greetings': Icons.waving_hand_outlined,
    'family': Icons.groups_2_outlined,
    'food': Icons.restaurant_outlined,
    'travel': Icons.flight_takeoff_rounded,
    'work': Icons.business_center_outlined,
    'technology': Icons.laptop_mac_outlined,
    'education': Icons.school_outlined,
    'health': Icons.favorite_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final items = topics.isEmpty
        ? _fallback.map((key) => TopicProgressItem(topic: key)).toList()
        : topics.take(6).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((topic) {
            final key = topic.topic.toLowerCase();
            final label = MiniTestBank.displayName(key) ?? _topicLabel(key);
            return SizedBox(
              width: width,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await context.read<FlashcardProvider>().setTopic(
                      topic.topic,
                    );
                    if (context.mounted) context.go('/flashcard');
                  },
                  borderRadius: BorderRadius.circular(17),
                  child: Ink(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.luxurySurface,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: AppColors.luxuryBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0D716B,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _icons.entries
                                .firstWhere(
                                  (entry) => key.contains(entry.key),
                                  orElse: () => const MapEntry(
                                    'general',
                                    Icons.auto_stories_outlined,
                                  ),
                                )
                                .value,
                            color: const Color(0xFF0D716B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  color: AppColors.luxuryEspresso,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                topic.total > 0
                                    ? '${topic.mastered}/${topic.total} đã thành thạo'
                                    : 'Mở bộ thẻ chủ đề',
                                style: GoogleFonts.nunito(
                                  color: AppColors.luxuryText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.luxuryTextHint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _topicLabel(String key) {
    const labels = {
      'greetings': 'Chào hỏi',
      'family': 'Gia đình',
      'food': 'Ẩm thực',
      'travel': 'Du lịch',
      'work': 'Công việc',
      'technology': 'Công nghệ',
      'education': 'Giáo dục',
      'health': 'Sức khỏe',
      'general': 'Tổng hợp',
    };
    return labels[key] ?? key;
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final quizzes = stats.recentQuizzes.take(3).toList();
    final words = stats.recentVocabs.take(3).toList();
    if (quizzes.isEmpty && words.isEmpty) {
      return _FirstDayCard(
        onStart: () => context.go('/flashcard?starter=true'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          eyebrow: 'DẤU VẾT GẦN ĐÂY',
          title: 'Bạn vừa đi qua',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.luxurySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.luxuryBorder),
          ),
          child: Column(
            children: [
              for (final quiz in quizzes)
                _ActivityRow(
                  icon: Icons.quiz_outlined,
                  title: 'Quiz ${quiz.quizType}',
                  caption:
                      '${quiz.correctAnswers}/${quiz.totalQuestions} câu đúng',
                  trailing: '${quiz.scorePercent.round()}%',
                ),
              for (final word in words)
                _ActivityRow(
                  icon: Icons.bookmark_added_outlined,
                  title: word.word,
                  caption: word.meaning,
                  trailing: _relativeDate(word.createdAt),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _relativeDate(DateTime? date) {
    if (date == null) return 'Gần đây';
    final days = DateTime.now().difference(date.toLocal()).inDays;
    if (days <= 0) return 'Hôm nay';
    if (days == 1) return 'Hôm qua';
    return '$days ngày';
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.caption,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String caption;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D716B), size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: AppColors.luxuryEspresso,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: AppColors.luxuryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: GoogleFonts.nunito(
              color: const Color(0xFFE95F52),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstDayCard extends StatelessWidget {
  const _FirstDayCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE95F52).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          const CatWidget(size: 72, expression: CatExpression.happy),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngày đầu tiên bắt đầu từ 5 thẻ',
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.luxuryEspresso,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hoàn thành một phiên ngắn để tạo dấu mốc đầu tiên.',
                  style: GoogleFonts.nunito(
                    color: AppColors.luxuryText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE95F52),
              foregroundColor: Colors.white,
            ),
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: GoogleFonts.nunito(
                  color: const Color(0xFFE95F52),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.25,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.luxuryEspresso,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _HomeSidebar extends StatelessWidget {
  const _HomeSidebar({required this.displayName, required this.level});

  final String displayName;
  final int level;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Hôm nay', '/'),
      (Icons.quiz_outlined, 'Quiz', '/quiz'),
      (Icons.style_outlined, 'Flashcard', '/flashcard'),
      (Icons.assignment_outlined, 'Kiểm tra', '/mock-test'),
      (Icons.person_outline_rounded, 'Hồ sơ', '/profile'),
    ];
    return Container(
      width: 238,
      color: const Color(0xFF123F3B),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(size: 48, showName: true, light: true),
          const SizedBox(height: 38),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _SidebarItem(
                icon: item.$1,
                label: item.$2,
                selected: item.$3 == '/',
                onTap: () => context.go(item.$3),
              ),
            ),
          const Spacer(),
          InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE95F52),
                    foregroundColor: Colors.white,
                    child: Text(
                      displayName.isEmpty ? 'S' : displayName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Cấp $level',
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
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
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF8EC) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? const Color(0xFF123F3B) : Colors.white70,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: selected ? const Color(0xFF123F3B) : Colors.white70,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(_fade);
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
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

class _AirmailHeroPattern extends StatelessWidget {
  const _AirmailHeroPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AirmailHeroPainter());
  }
}

class _AirmailHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()..color = Colors.white.withValues(alpha: 0.055);
    canvas.drawCircle(Offset(size.width * 0.92, 18), 110, soft);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.86), 74, soft);
    final line = Paint()
      ..color = const Color(0xFF65B8CB).withValues(alpha: 0.38)
      ..strokeWidth = 8;
    final coral = Paint()
      ..color = const Color(0xFFE95F52).withValues(alpha: 0.45)
      ..strokeWidth = 8;
    for (double x = -40; x < size.width + 60; x += 76) {
      canvas.drawLine(
        Offset(x, size.height - 5),
        Offset(x + 32, size.height - 5),
        coral,
      );
      canvas.drawLine(
        Offset(x + 36, size.height - 5),
        Offset(x + 68, size.height - 5),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
