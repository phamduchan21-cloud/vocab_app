import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_logo.dart';
import '../widgets/auth_postcard.dart';
import '../widgets/cat_widget.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final _pageController = PageController();
  int _page = 0;
  String _level = 'beginner';
  int _dailyGoal = 10;
  String _purpose = 'general';
  bool _placementTest = false;
  String? _errorMessage;

  bool get _isSaving => context.watch<ProfileProvider>().isUpdatingProfile;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _move(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    final profile = context.read<ProfileProvider>();
    final error = await profile.completeOnboarding(
      englishLevel: _level,
      dailyWordGoal: _dailyGoal,
      learningGoals: {
        'purpose': _purpose,
        'daily_minutes': _dailyGoal <= 5 ? 5 : 10,
        'placement_test': _placementTest,
        'onboarding_completed': true,
      },
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    try {
      await context.read<AuthProvider>().completeOnboarding();
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Đã lưu lộ trình nhưng chưa thể hoàn tất tài khoản. Vui lòng thử lại.',
        );
      }
      return;
    }
    if (!mounted) return;
    if (_placementTest) {
      final testLevel = _level == 'elementary' ? 'beginner' : _level;
      context.go(
        '/mock-test/play/$testLevel?purpose=placement&count=5&duration=2',
      );
    } else {
      context.go('/flashcard?starter=true');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const AppLogo(size: 46, showName: true),
                  const Spacer(),
                  Text(
                    'BƯỚC ${_page + 1}/3',
                    style: GoogleFonts.nunito(
                      color: AppColors.luxuryBrown,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_page + 1) / 3,
                  minHeight: 7,
                  backgroundColor: AppColors.luxuryBorder,
                  color: const Color(0xFFE95F52),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _SetupPage(
                    eyebrow: 'ĐỊA CHỈ KHỞI HÀNH',
                    title: 'Bạn đang ở đâu trên hành trình tiếng Anh?',
                    subtitle:
                        'Lựa chọn này giúp SolVocab chọn từ và câu hỏi vừa sức.',
                    child: _ChoiceGrid(
                      selected: _level,
                      onSelected: (value) => setState(() => _level = value),
                      options: const [
                        _Choice(
                          'beginner',
                          'Mới bắt đầu',
                          'A0–A1',
                          Icons.spa_outlined,
                        ),
                        _Choice(
                          'elementary',
                          'Cơ bản',
                          'A1–A2',
                          Icons.eco_outlined,
                        ),
                        _Choice(
                          'intermediate',
                          'Trung cấp',
                          'B1–B2',
                          Icons.trending_up_rounded,
                        ),
                        _Choice(
                          'advanced',
                          'Nâng cao',
                          'C1+',
                          Icons.workspace_premium_outlined,
                        ),
                      ],
                    ),
                  ),
                  _SetupPage(
                    eyebrow: 'NHỊP GỬI MỖI NGÀY',
                    title: 'Bạn muốn ghi nhớ bao nhiêu từ?',
                    subtitle:
                        'Mục tiêu này sẽ xuất hiện ngay trong Hồ sơ và báo cáo tiến độ.',
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [5, 10, 15, 20]
                          .map(
                            (goal) => ChoiceChip(
                              selected: _dailyGoal == goal,
                              onSelected: (_) =>
                                  setState(() => _dailyGoal = goal),
                              avatar: Icon(
                                goal == 10
                                    ? Icons.local_fire_department_rounded
                                    : Icons.local_post_office_outlined,
                                size: 20,
                              ),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                child: Text('$goal từ / ngày'),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  _SetupPage(
                    eyebrow: 'ĐIỂM ĐẾN',
                    title: 'Bạn học tiếng Anh để làm gì?',
                    subtitle:
                        'Bạn có thể làm bài xếp lớp 2 phút hoặc bắt đầu ngay với 5 thẻ.',
                    child: Column(
                      children: [
                        _ChoiceGrid(
                          selected: _purpose,
                          onSelected: (value) =>
                              setState(() => _purpose = value),
                          options: const [
                            _Choice(
                              'general',
                              'Giao tiếp',
                              'Hằng ngày',
                              Icons.forum_outlined,
                            ),
                            _Choice(
                              'exam',
                              'Thi cử',
                              'IELTS · TOEIC',
                              Icons.school_outlined,
                            ),
                            _Choice(
                              'work',
                              'Công việc',
                              'Business',
                              Icons.work_outline_rounded,
                            ),
                            _Choice(
                              'travel',
                              'Du lịch',
                              'Khám phá',
                              Icons.flight_takeoff_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          value: _placementTest,
                          onChanged: (value) =>
                              setState(() => _placementTest = value),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          secondary: const Icon(Icons.fact_check_outlined),
                          title: const Text('Làm mini test xếp lớp 2 phút'),
                          subtitle: const Text(
                            '5 câu để gợi ý độ khó phù hợp hơn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AuthStatusBanner(message: _errorMessage!, error: true),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Row(
                  children: [
                    if (_page > 0)
                      IconButton.outlined(
                        tooltip: 'Quay lại',
                        onPressed: _isSaving ? null : () => _move(_page - 1),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    if (_page > 0) const SizedBox(width: 12),
                    Expanded(
                      child: StampSubmitButton(
                        label: _page == 2
                            ? (_placementTest
                                  ? 'Bắt đầu xếp lớp'
                                  : 'Học 5 thẻ đầu tiên')
                            : 'Tiếp tục',
                        icon: _page == 2
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        isLoading: _isSaving,
                        onPressed: _page == 2
                            ? _complete
                            : () => _move(_page + 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  const _SetupPage({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            children: [
              const CatWidget(size: 92, expression: CatExpression.happy),
              const SizedBox(height: 16),
              Text(
                eyebrow,
                style: GoogleFonts.nunito(
                  color: const Color(0xFFE95F52),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.luxuryEspresso,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  fontSize: 31,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.luxuryText,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 26),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_Choice> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 480
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final active = option.value == selected;
            return SizedBox(
              width: width,
              child: Semantics(
                selected: active,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(option.value),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFFFEEE9)
                          : AppColors.luxurySurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: active
                            ? const Color(0xFFE95F52)
                            : AppColors.luxuryBorder,
                        width: active ? 1.7 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          color: active
                              ? const Color(0xFFE95F52)
                              : AppColors.luxuryBrown,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.title,
                                style: GoogleFonts.nunito(
                                  color: AppColors.luxuryEspresso,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                option.subtitle,
                                style: GoogleFonts.nunito(
                                  color: AppColors.luxuryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          active
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: active
                              ? const Color(0xFFE95F52)
                              : AppColors.luxuryBorder,
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
}

class _Choice {
  const _Choice(this.value, this.title, this.subtitle, this.icon);

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
}
