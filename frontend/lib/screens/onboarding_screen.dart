import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../widgets/cat_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  final int _totalPages = 9; // 1 chào + 8 câu hỏi
  final Map<int, dynamic> _answers = {};

  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Câu cuối → chuyển login
      context.go('/login');
    }
  }

  bool get _canProceed {
    if (_currentPage == 0) return true;
    return _answers.containsKey(_currentPage) && _answers[_currentPage] != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildProgressDots(),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildWelcomePage();
                  return _buildQuestionPage(index);
                },
              ),
            ),
            // Bottom button
            _buildBottomButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final isDone = index < _currentPage;
        final isCurrent = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: isDone || isCurrent
                ? AppTheme.primaryGradient
                : null,
            color: isDone || isCurrent ? null : const Color(0xFFE5E7EB),
          ),
        );
      }),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Mèo
          AnimatedBuilder(
            animation: _bounceAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -_bounceAnim.value),
              child: child,
            ),
            child: const CatWidget(
              size: 140,
              expression: CatExpression.happy,
            ),
          ),
          const SizedBox(height: 32),
          // Speech bubble
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.catLight,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Chào bạn! 🐱',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tớ là Meu!',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          // Speech bubble tail
          CustomPaint(
            size: const Size(24, 12),
            painter: _TrianglePainter(AppColors.catLight),
          ),
          const Spacer(),
          Text(
            'Hãy trả lời 8 câu hỏi nhỏ\nđể tớ hiểu bạn hơn nhé!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final questionData = _questions[index - 1];
    final isSingle = questionData['type'] == 'single';
    final selectedSingle = isSingle ? _answers[index] as String? : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Mèo nhỏ + câu hỏi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -_bounceAnim.value * 0.5),
                  child: child,
                ),
                child: const CatWidget(
                  size: 56,
                  expression: CatExpression.talking,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.catLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    questionData['question'] as String,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Các lựa chọn
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: (questionData['options'] as List<Map<String, dynamic>>).map((opt) {
                final value = opt['value'] as String;
                final icon = opt['icon'] as String?;
                final isSelected = isSingle
                    ? selectedSingle == value
                    : (_answers[index] as List<String>?)?.contains(value) ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildOptionCard(
                    icon: icon,
                    label: value,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSingle) {
                          _answers[index] = value;
                        } else {
                          final current = (_answers[index] as List<String>?)?.toList() ?? <String>[];
                          if (current.contains(value)) {
                            current.remove(value);
                          } else {
                            current.add(value);
                          }
                          _answers[index] = current;
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    String? icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.catLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final isLastPage = _currentPage == _totalPages - 1;
    final buttonText = isLastPage ? 'Bắt đầu hành trình!' : 'Tiếp tục';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _canProceed ? AppTheme.primaryButtonGradient : null,
            color: _canProceed ? null : const Color(0xFFE5E7EB),
            boxShadow: _canProceed
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: _canProceed ? _goNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: _canProceed ? Colors.white : AppColors.textHint,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonText,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLastPage)
                  const SizedBox(width: 8)
                else
                  const SizedBox(width: 8),
                if (isLastPage)
                  const Icon(Icons.auto_stories_rounded, size: 22)
                else
                  const Icon(Icons.arrow_forward_rounded, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 8 câu hỏi onboarding
final List<Map<String, dynamic>> _questions = [
  {
    'question': 'Trước hết, bạn muốn học ngôn ngữ gì?',
    'type': 'single',
    'options': [
      {'icon': '🇬🇧', 'value': 'Tiếng Anh'},
      {'icon': '🇯🇵', 'value': 'Tiếng Nhật'},
      {'icon': '🇰🇷', 'value': 'Tiếng Hàn'},
      {'icon': '🇨🇳', 'value': 'Tiếng Trung'},
      {'icon': '🇫🇷', 'value': 'Tiếng Pháp'},
      {'icon': '🇩🇪', 'value': 'Tiếng Đức'},
      {'icon': '🌐', 'value': 'Ngôn ngữ khác'},
    ],
  },
  {
    'question': 'Trình độ hiện tại của bạn thế nào?',
    'type': 'single',
    'options': [
      {'icon': '🌱', 'value': 'Mới bắt đầu'},
      {'icon': '📗', 'value': 'Cơ bản (A1-A2)'},
      {'icon': '📘', 'value': 'Trung cấp (B1-B2)'},
      {'icon': '📕', 'value': 'Nâng cao (C1-C2)'},
    ],
  },
  {
    'question': 'Tại sao bạn muốn học ngôn ngữ này?',
    'type': 'multi',
    'options': [
      {'icon': '🎯', 'value': 'Đi làm / CV'},
      {'icon': '✈️', 'value': 'Du lịch'},
      {'icon': '🎓', 'value': 'Học tập'},
      {'icon': '🎬', 'value': 'Giải trí (phim/nhạc)'},
      {'icon': '💬', 'value': 'Giao tiếp bạn bè'},
      {'icon': '🏡', 'value': 'Khác'},
    ],
  },
  {
    'question': 'Bạn muốn dành bao nhiêu phút mỗi ngày?',
    'type': 'single',
    'options': [
      {'icon': '⚡', 'value': '5 phút (nhanh)'},
      {'icon': '🔥', 'value': '15 phút (vừa)'},
      {'icon': '💪', 'value': '30 phút (nhiều)'},
      {'icon': '🏆', 'value': '60 phút (siêng)'},
    ],
  },
  {
    'question': 'Bạn thích học theo cách nào?',
    'type': 'multi',
    'options': [
      {'icon': '👁️', 'value': 'Nhìn (hình ảnh)'},
      {'icon': '👂', 'value': 'Nghe (âm thanh)'},
      {'icon': '✍️', 'value': 'Viết (ghi chép)'},
      {'icon': '🗣️', 'value': 'Nói (thực hành)'},
      {'icon': '📖', 'value': 'Đọc (sách/báo)'},
    ],
  },
  {
    'question': 'Bạn có mục tiêu cụ thể gì không?',
    'type': 'single',
    'options': [
      {'icon': '🗣️', 'value': 'Giao tiếp cơ bản'},
      {'icon': '📝', 'value': 'Đậu kỳ thi'},
      {'icon': '🎬', 'value': 'Xem phim không sub'},
      {'icon': '📖', 'value': 'Đọc sách báo'},
      {'icon': '🌍', 'value': 'Du lịch tự tin'},
    ],
  },
  {
    'question': 'Bạn muốn học vào thời gian nào trong ngày?',
    'type': 'single',
    'options': [
      {'icon': '🌅', 'value': 'Sáng sớm (6-8h)'},
      {'icon': '☀️', 'value': 'Buổi sáng (8-12h)'},
      {'icon': '🌤️', 'value': 'Buổi trưa (12-14h)'},
      {'icon': '🌆', 'value': 'Buổi chiều (14-18h)'},
      {'icon': '🌙', 'value': 'Buổi tối (18-22h)'},
      {'icon': '🌃', 'value': 'Khuya (22-0h)'},
    ],
  },
  {
    'question': 'Cuối cùng, bạn có muốn nhắc nhở học hàng ngày không?',
    'type': 'single',
    'options': [
      {'icon': '🔔', 'value': 'Có, 8:00 sáng'},
      {'icon': '🔔', 'value': 'Có, 12:00 trưa'},
      {'icon': '🔔', 'value': 'Có, 20:00 tối'},
      {'icon': '❌', 'value': 'Không cần nhắc'},
    ],
  },
];

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
