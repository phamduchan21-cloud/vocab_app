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

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _introCount = 3;
  static const _totalPages = _introCount + 3 + 1;
  final _pageController = PageController();
  final Map<int, int> _answers = {};
  int _currentPage = 0;

  bool get _isQuestion => _currentPage >= _introCount && _currentPage < _totalPages - 1;
  bool get _isLast => _currentPage == _totalPages - 1;
  bool get _canContinue => !_isQuestion || _answers.containsKey(_currentPage);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _continue() {
    if (!_canContinue) return;
    if (_isLast) {
      context.go('/register');
    } else {
      _goTo(_currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxuryBg,
      body: SafeArea(
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: _currentPage == 0
                          ? null
                          : IconButton(
                              tooltip: 'Quay lại',
                              onPressed: () => _goTo(_currentPage - 1),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                    ),
                    Expanded(
                      child: Semantics(
                        label: 'Tiến độ ${_currentPage + 1} trên $_totalPages',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_currentPage + 1) / _totalPages,
                            minHeight: 7,
                            backgroundColor: AppColors.luxuryBorder,
                            color: AppColors.luxuryBrown,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 76,
                      child: _isLast
                          ? null
                          : TextButton(
                              onPressed: () => _goTo(_totalPages - 1),
                              child: const Text('Bỏ qua'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _totalPages,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  if (index < _introCount) return _IntroPage(data: _intros[index]);
                  if (index < _totalPages - 1) {
                    final question = _questions[index - _introCount];
                    return _QuestionPage(
                      data: question,
                      selected: _answers[index],
                      onSelected: (value) => setState(() => _answers[index] = value),
                    );
                  }
                  return const _FinishPage();
                },
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _canContinue ? _continue : null,
                    iconAlignment: IconAlignment.end,
                    icon: Icon(_isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded),
                    label: Text(_isLast ? 'Tạo tài khoản miễn phí' : 'Tiếp tục'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.data});

  final _IntroData data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            children: [
              Container(
                width: 156,
                height: 156,
                decoration: BoxDecoration(
                  gradient: data.coral
                      ? AppTheme.heroGradient
                      : AppColors.luxuryGradient,
                  borderRadius: BorderRadius.circular(48),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.luxuryBrown.withValues(alpha: 0.16),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: Colors.white, size: 68),
              ),
              const SizedBox(height: 34),
              Text(
                data.eyebrow.toUpperCase(),
                style: GoogleFonts.nunito(
                  color: AppColors.luxuryGold,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  height: 1.18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryEspresso,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  height: 1.55,
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

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({required this.data, required this.selected, required this.onSelected});

  final _QuestionData data;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryEspresso,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 15, color: AppColors.luxuryText),
              ),
              const SizedBox(height: 28),
              ...List.generate(data.options.length, (index) {
                final option = data.options[index];
                final isSelected = selected == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    selected: isSelected,
                    button: true,
                    child: InkWell(
                      onTap: () => onSelected(index),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.blueBg : AppColors.luxurySurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppColors.luxuryBrown : AppColors.luxuryBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(option.icon, color: isSelected ? AppColors.luxuryBrown : AppColors.luxuryText),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                option.label,
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.luxuryEspresso,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: isSelected ? AppColors.luxuryBrown : AppColors.luxuryBorder,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinishPage extends StatelessWidget {
  const _FinishPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              const CatWidget(size: 144, expression: CatExpression.happy),
              const SizedBox(height: 22),
              Text(
                'Lộ trình của bạn đã sẵn sàng',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.luxuryEspresso,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Chỉ cần vài phút mỗi ngày. SolVocab sẽ giúp bạn ôn đúng từ, vào đúng thời điểm.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 16, height: 1.55, color: AppColors.luxuryText),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.sunnyBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: AppColors.luxuryGold),
                    SizedBox(width: 8),
                    Flexible(child: Text('Mục tiêu đầu tiên: hoàn thành một phiên học hôm nay')),
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

class _IntroData {
  const _IntroData({required this.icon, required this.eyebrow, required this.title, required this.description, this.coral = false});
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final bool coral;
}

class _QuestionData {
  const _QuestionData({required this.title, required this.subtitle, required this.options});
  final String title;
  final String subtitle;
  final List<_OptionData> options;
}

class _OptionData {
  const _OptionData(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _intros = [
  _IntroData(
    icon: Icons.eco_rounded,
    eyebrow: 'Học có định hướng',
    title: 'Nuôi dưỡng vốn từ, từng ngày một',
    description: 'Bài học ngắn gọn, rõ mục tiêu và vừa vặn với nhịp sống của bạn.',
  ),
  _IntroData(
    icon: Icons.psychology_alt_rounded,
    eyebrow: 'Ghi nhớ thông minh',
    title: 'Ôn đúng từ vào đúng lúc',
    description: 'Flashcard và luyện tập ngắt quãng giúp kiến thức ở lại lâu hơn.',
    coral: true,
  ),
  _IntroData(
    icon: Icons.insights_rounded,
    eyebrow: 'Thấy rõ tiến bộ',
    title: 'Mỗi phiên học đều có ý nghĩa',
    description: 'Theo dõi chuỗi ngày học, từ đã thành thạo và mục tiêu tiếp theo.',
  ),
];

const _questions = [
  _QuestionData(
    title: 'Bạn học từ vựng để làm gì?',
    subtitle: 'SolVocab sẽ ưu tiên nội dung phù hợp với mục tiêu này.',
    options: [
      _OptionData(Icons.work_outline_rounded, 'Công việc và giao tiếp'),
      _OptionData(Icons.school_outlined, 'Thi cử và học tập'),
      _OptionData(Icons.flight_takeoff_rounded, 'Du lịch và khám phá'),
      _OptionData(Icons.favorite_outline_rounded, 'Phát triển bản thân'),
    ],
  ),
  _QuestionData(
    title: 'Trình độ hiện tại của bạn?',
    subtitle: 'Không cần chính xác tuyệt đối, bạn có thể điều chỉnh sau.',
    options: [
      _OptionData(Icons.spa_outlined, 'Mới bắt đầu'),
      _OptionData(Icons.trending_up_rounded, 'Cơ bản'),
      _OptionData(Icons.auto_graph_rounded, 'Trung cấp'),
      _OptionData(Icons.workspace_premium_outlined, 'Nâng cao'),
    ],
  ),
  _QuestionData(
    title: 'Bạn muốn học bao lâu mỗi ngày?',
    subtitle: 'Một mục tiêu thực tế sẽ dễ duy trì hơn.',
    options: [
      _OptionData(Icons.bolt_rounded, '5 phút · Khởi động nhẹ'),
      _OptionData(Icons.timer_outlined, '10 phút · Nhịp đều đặn'),
      _OptionData(Icons.local_fire_department_outlined, '15 phút · Tăng tốc'),
      _OptionData(Icons.rocket_launch_outlined, '20 phút · Quyết tâm cao'),
    ],
  ),
];
