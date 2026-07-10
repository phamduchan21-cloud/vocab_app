import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../widgets/cat_widget.dart';

/// Màn hình Onboarding — phong cách Editorial Luxury, giữ mascot MeuBeu.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  /// Tong so trang: 4 feature intro + 8 cau hoi + 1 ket thuc = 13
  static const int _featurePages = 4;
  static const int _questionCount = 8;
  static const int _totalPages = _featurePages + _questionCount + 1;

  final Map<int, dynamic> _answers = {};

  // Animations
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounce;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounce = Tween<double>(begin: 6, end: 0).animate(
      CurvedAnimation(
        parent: _bounceCtrl,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulse = Tween<double>(begin: 0, end: 0.7).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    _bounceCtrl.forward();
    _pulseCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _isFeaturePage => _currentPage < _featurePages;
  bool get _isFinishPage => _currentPage == _totalPages - 1;

  bool get _canProceed {
    if (_isFeaturePage || _isFinishPage) return true;
    return _answers.containsKey(_currentPage) && _answers[_currentPage] != null;
  }

  void _goNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      );
    } else {
      context.go('/login');
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 500),
      curve: const Cubic(0.34, 1.56, 0.64, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back + progress dots + skip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: const Cubic(0.34, 1.56, 0.64, 1),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: AppColors.luxuryBrown.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.luxuryBorder,
                            width: 0.5,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.luxurySurface,
                            borderRadius: BorderRadius.circular(26.5),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: AppColors.luxuryEspresso,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),

                  const Spacer(),

                  _buildProgressDots(),

                  const Spacer(),

                  if (!_isFinishPage)
                    GestureDetector(
                      onTap: _skip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.luxurySurface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.luxuryBorder,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Bỏ qua',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.luxuryTextHint,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                itemCount: _totalPages,
                itemBuilder: (context, i) {
                  if (i < _featurePages) {
                    return _buildFeaturePage(i);
                  } else if (i < _totalPages - 1) {
                    return _buildQuestionPage(i);
                  } else {
                    return _buildFinishPage();
                  }
                },
              ),
            ),

            // Bottom bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // Progress dots
  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (i) {
        final isActive = i == _currentPage;
        final isDone = i < _currentPage;
        final size = isActive ? 8.0 : 6.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDone
                ? AppColors.luxuryGold
                : isActive
                    ? AppColors.luxuryGold
                    : AppColors.luxuryBorder,
          ),
        );
      }),
    );
  }

  // Feature intro pages (0-3)
  Widget _buildFeaturePage(int index) {
    final feature = _features[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          _FeatureIllustration(
            icon: feature.icon,
            gradient: [AppColors.luxuryBrown, AppColors.luxuryBrownLight],
            pulse: _pulse,
          ),

          const SizedBox(height: 40),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.luxuryGold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.luxuryGold.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              feature.badge,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.luxuryGold,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            feature.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.luxuryEspresso,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            feature.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: AppColors.luxuryText,
              height: 1.5,
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  static const _features = [
    _FeatureData(
      icon: Icons.auto_stories_rounded,
      badge: 'HOC TU VUNG',
      title: 'Flashcard thong minh\nGhi nho sieu toc',
      description:
          'Hoc tu moi moi ngay voi he thong flashcard tich hop\nphuong phap lap lai ngat quang (SRS).',
      gradient: AppColors.luxuryGradient,
    ),
    _FeatureData(
      icon: Icons.quiz_rounded,
      badge: 'KIEM TRA',
      title: 'Quiz & Mini-test\nDo trinh do thuc te',
      description:
          'Trac nghiem 4 dap an, mini-test tong hop va mock test\nmo phong de thi that.',
      gradient: AppColors.luxuryGradient,
    ),
    _FeatureData(
      icon: Icons.bar_chart_rounded,
      badge: 'THEO DOI',
      title: 'Thong ke chi tiet\nDong luc moi ngay',
      description:
          'Theo doi streak, XP, gems va bieu do tien do tuan.\nCanh tranh cung ban be qua leaderboard.',
      gradient: AppColors.luxuryGradient,
    ),
    _FeatureData(
      icon: Icons.smart_toy_rounded,
      badge: 'AI CHAT',
      title: 'Tro chuyen cung AI\nLuyen phan xa tieng Anh',
      description:
          'Chat voi tro ly AI de thuc hanh hoi thoai,\nsua loi ngu phap va mo rong von tu.',
      gradient: AppColors.luxuryGradient,
    ),
  ];

  // Question pages (dang chat - MeuBeu hoi)
  Widget _buildQuestionPage(int pageIndex) {
    final qIdx = pageIndex - _featurePages;
    final questionData = _questions[qIdx];
    final isMulti = questionData['type'] == 'multi';
    final options = questionData['options'] as List<Map<String, dynamic>>;
    final selected = _answers[pageIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // MeuBeu bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Cat avatar dalam Double-Bezel
              AnimatedBuilder(
                animation: _bounce,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -_bounce.value),
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: AppColors.luxuryBrown.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.luxuryBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.luxurySurface,
                      borderRadius: BorderRadius.circular(26.5),
                    ),
                    child: const CatWidget(
                      size: 48,
                      expression: CatExpression.talking,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Speech bubble
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.luxurySurface,
                    borderRadius: BorderRadius.only(
                      topRight: const Radius.circular(18),
                      bottomLeft: const Radius.circular(18),
                      bottomRight: const Radius.circular(18),
                    ),
                    border: Border.all(
                      color: AppColors.luxuryBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cau ${qIdx + 1}',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.luxuryGold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        questionData['question'] as String,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.luxuryEspresso,
                          height: 1.4,
                        ),
                      ),
                      if (isMulti)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '(Chon nhieu dap an)',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppColors.luxuryTextHint,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Options
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final opt = options[i];
                final value = opt['value'] as String;
                final icon = opt['icon'] as String?;
                final isSelected = isMulti
                    ? (selected as List<String>?)?.contains(value) ?? false
                    : selected == value;

                return _OptionCard(
                  icon: icon,
                  label: value,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isMulti) {
                        final current =
                            (selected as List<String>?)?.toList() ?? [];
                        if (current.contains(value)) {
                          current.remove(value);
                        } else {
                          current.add(value);
                        }
                        _answers[pageIndex] = current;
                      } else {
                        _answers[pageIndex] = value;
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Finish page
  Widget _buildFinishPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Cat dalam Double-Bezel
          AnimatedBuilder(
            animation: _bounce,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -_bounce.value),
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: AppColors.luxuryBrown.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.luxuryBorder,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.luxuryBrown.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.luxurySurface,
                  borderRadius: BorderRadius.circular(26.5),
                ),
                child: const CatWidget(
                  size: 130,
                  expression: CatExpression.happy,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Tuyet voi!',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.luxuryEspresso,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'MeuBeu da hieu ban hon roi!\nHay bat dau hanh trinh hoc tap nhe!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: AppColors.luxuryText,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Summary pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _buildSummaryPills(),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  List<Widget> _buildSummaryPills() {
    final pills = <Widget>[];
    final labels = [
      'Ngon ngu',
      'Trinh do',
      'Muc tieu',
      'Thoi gian',
      'Phong cach',
    ];
    for (int i = 0; i < labels.length; i++) {
      final answerIdx = _featurePages + i;
      final answer = _answers[answerIdx];
      if (answer == null) continue;
      final display = answer is List ? answer.join(', ') : answer.toString();
      if (display.length > 20) continue;

      pills.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.luxuryGold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.luxuryGold.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labels[i],
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.luxuryGold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                ': $display',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: AppColors.luxuryText,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return pills;
  }

  // Bottom bar
  Widget _buildBottomBar() {
    final String text;
    final IconData icon;

    if (_isFeaturePage) {
      text = 'Tiep tuc';
      icon = Icons.arrow_forward_rounded;
    } else if (_currentPage >= _featurePages && _currentPage < _totalPages - 1) {
      text = _currentPage == _totalPages - 2 ? 'Xem ket qua' : 'Tiep tuc';
      icon = _currentPage == _totalPages - 2
          ? Icons.check_rounded
          : Icons.arrow_forward_rounded;
    } else {
      text = 'Bat dau hoc ngay!';
      icon = Icons.auto_stories_rounded;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: GestureDetector(
          onTap: _canProceed ? _goNext : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: _canProceed
                  ? AppColors.luxuryGradient
                  : null,
              color: _canProceed ? null : AppColors.luxuryBorder,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _canProceed ? Colors.white : AppColors.luxuryTextHint,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 22,
                    color: _canProceed ? Colors.white : AppColors.luxuryTextHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widgets

class _FeatureIllustration extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final Animation<double> pulse;

  const _FeatureIllustration({
    required this.icon,
    required this.gradient,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow ring
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) => Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.luxuryGold.withValues(alpha: pulse.value * 0.15),
                    AppColors.luxuryGold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                colors: [AppColors.luxuryBrown, AppColors.luxuryBrownLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.luxuryBrown.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 56, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String? icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.luxuryGold.withValues(alpha: 0.08)
              : AppColors.luxurySurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? AppColors.luxuryGold
                : AppColors.luxuryBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.luxuryEspresso : AppColors.luxuryText,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.luxuryGold,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
          ],
        ),
      ),
    );
  }
}

// Data classes
class _FeatureData {
  final IconData icon;
  final String badge;
  final String title;
  final String description;
  final LinearGradient gradient;

  const _FeatureData({
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

// 8 cau hoi onboarding
final List<Map<String, dynamic>> _questions = [
  {
    'question': 'Ban muon hoc ngon ngu gi?',
    'type': 'single',
    'options': [
      {'icon': '\u{1F1EC}\u{1F1E7}', 'value': 'Tieng Anh'},
      {'icon': '\u{1F1EF}\u{1F1F5}', 'value': 'Tieng Nhat'},
      {'icon': '\u{1F1F0}\u{1F1F7}', 'value': 'Tieng Han'},
      {'icon': '\u{1F1E8}\u{1F1F3}', 'value': 'Tieng Trung'},
      {'icon': '\u{1F1EB}\u{1F1F7}', 'value': 'Tieng Phap'},
      {'icon': '\u{1F310}', 'value': 'Ngon ngu khac'},
    ],
  },
  {
    'question': 'Trinh do hien tai cua ban the nao?',
    'type': 'single',
    'options': [
      {'icon': '\u{1F331}', 'value': 'Moi bat dau'},
      {'icon': '\u{1F4D7}', 'value': 'Co ban (A1-A2)'},
      {'icon': '\u{1F4D8}', 'value': 'Trung cap (B1-B2)'},
      {'icon': '\u{1F4D5}', 'value': 'Nang cao (C1-C2)'},
    ],
  },
  {
    'question': 'Tai sao ban muon hoc ngon ngu nay?',
    'type': 'multi',
    'options': [
      {'icon': '\u{1F3AF}', 'value': 'Di lam / CV'},
      {'icon': '\u{2708}\u{FE0F}', 'value': 'Du lich'},
      {'icon': '\u{1F393}', 'value': 'Hoc tap'},
      {'icon': '\u{1F3AC}', 'value': 'Giai tri (phim/nhac)'},
      {'icon': '\u{1F4AC}', 'value': 'Giao tiep ban be'},
      {'icon': '\u{1F3E1}', 'value': 'Khac'},
    ],
  },
  {
    'question': 'Ban muon danh bao nhieu phut moi ngay?',
    'type': 'single',
    'options': [
      {'icon': '\u{26A1}', 'value': '5 phut (nhanh)'},
      {'icon': '\u{1F525}', 'value': '15 phut (vua)'},
      {'icon': '\u{1F4AA}', 'value': '30 phut (nhieu)'},
      {'icon': '\u{1F3C6}', 'value': '60 phut (sieng)'},
    ],
  },
  {
    'question': 'Ban thich hoc theo cach nao?',
    'type': 'multi',
    'options': [
      {'icon': '\u{1F441}\u{FE0F}', 'value': 'Nhin (hinh anh)'},
      {'icon': '\u{1F442}', 'value': 'Nghe (am thanh)'},
      {'icon': '\u{270D}\u{FE0F}', 'value': 'Viet (ghi chep)'},
      {'icon': '\u{1F5E3}\u{FE0F}', 'value': 'Noi (thuc hanh)'},
      {'icon': '\u{1F4D6}', 'value': 'Doc (sach/bao)'},
    ],
  },
  {
    'question': 'Ban co muc tieu cu the gi khong?',
    'type': 'single',
    'options': [
      {'icon': '\u{1F5E3}\u{FE0F}', 'value': 'Giao tiep co ban'},
      {'icon': '\u{1F4DD}', 'value': 'Dau ky thi'},
      {'icon': '\u{1F3AC}', 'value': 'Xem phim khong sub'},
      {'icon': '\u{1F4D6}', 'value': 'Doc sach bao'},
      {'icon': '\u{1F30D}', 'value': 'Du lich tu tin'},
    ],
  },
  {
    'question': 'Ban muon hoc vao thoi gian nao trong ngay?',
    'type': 'single',
    'options': [
      {'icon': '\u{1F305}', 'value': 'Sang som (6-8h)'},
      {'icon': '\u{2600}\u{FE0F}', 'value': 'Buoi sang (8-12h)'},
      {'icon': '\u{1F324}\u{FE0F}', 'value': 'Buoi trua (12-14h)'},
      {'icon': '\u{1F306}', 'value': 'Buoi chieu (14-18h)'},
      {'icon': '\u{1F319}', 'value': 'Buoi toi (18-22h)'},
    ],
  },
  {
    'question': 'Ban co muon nhac nho hoc hang ngay khong?',
    'type': 'single',
    'options': [
      {'icon': '\u{1F514}', 'value': 'Co, 8:00 sang'},
      {'icon': '\u{1F514}', 'value': 'Co, 12:00 trua'},
      {'icon': '\u{1F514}', 'value': 'Co, 20:00 toi'},
      {'icon': '\u{274C}', 'value': 'Khong can nhac'},
    ],
  },
];
