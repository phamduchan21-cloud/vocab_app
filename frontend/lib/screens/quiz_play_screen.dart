import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/quiz_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_bottom_nav.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  static const int _totalSeconds = 60; // Tăng từ 30 lên 60s

  // Mở rộng fallback questions từ 10 lên 25 câu đa dạng
  static const List<Map<String, dynamic>> _fallbackQuestions = [
    {'question': 'Từ "resilient" có nghĩa là gì?', 'options': ['Kiên cường, bền bỉ', 'Hoãn lại', 'Chân thật', 'Kết quả'], 'correctAnswer': 'Kiên cường, bền bỉ'},
    {'question': 'Từ "genuine" có nghĩa là gì?', 'options': ['Miễn cưỡng', 'Kết quả', 'Chân thật, thật sự', 'Thận trọng'], 'correctAnswer': 'Chân thật, thật sự'},
    {'question': 'Từ nào đồng nghĩa với "tough"?', 'options': ['fragile', 'resilient', 'gentle', 'cautious'], 'correctAnswer': 'resilient'},
    {'question': 'Trái nghĩa của "postpone" là?', 'options': ['delay', 'advance', 'cancel', 'reschedule'], 'correctAnswer': 'advance'},
    {'question': 'Be ___ when crossing the street at night.', 'options': ['resilient', 'postpone', 'cautious', 'genuine'], 'correctAnswer': 'cautious'},
    {'question': 'Từ "thrive" có nghĩa là gì?', 'options': ['Phát triển mạnh', 'Hoãn lại', 'Kết quả', 'Thận trọng'], 'correctAnswer': 'Phát triển mạnh'},
    {'question': 'Từ nào đồng nghĩa với "flourish"?', 'options': ['struggle', 'decline', 'thrive', 'pause'], 'correctAnswer': 'thrive'},
    {'question': 'Từ "reluctant" có nghĩa là gì?', 'options': ['Nhất quán', 'Miễn cưỡng, ngần ngại', 'Kiên cường', 'Chân thật'], 'correctAnswer': 'Miễn cưỡng, ngần ngại'},
    {'question': 'The ___ of the election was unexpected.', 'options': ['outcome', 'postpone', 'genuine', 'cautious'], 'correctAnswer': 'outcome'},
    {'question': 'Từ "consistent" có nghĩa là gì?', 'options': ['Thận trọng', 'Kết quả', 'Nhất quán, ổn định', 'Hoãn lại'], 'correctAnswer': 'Nhất quán, ổn định'},
    {'question': 'Từ "abundant" có nghĩa là gì?', 'options': ['Dồi dào, phong phú', 'Thiếu thốn', 'Mạnh mẽ', 'Nhanh nhẹn'], 'correctAnswer': 'Dồi dào, phong phú'},
    {'question': 'She gave a ___ speech that moved everyone.', 'options': ['tedious', 'passionate', 'confusing', 'resilient'], 'correctAnswer': 'passionate'},
    {'question': 'Từ "ambiguous" có nghĩa là gì?', 'options': ['Rõ ràng', 'Mơ hồ, không rõ ràng', 'Mạnh mẽ', 'Dễ thương'], 'correctAnswer': 'Mơ hồ, không rõ ràng'},
    {'question': 'Đồng nghĩa của "begin" là?', 'options': ['start', 'stop', 'delay', 'cancel'], 'correctAnswer': 'start'},
    {'question': 'Trái nghĩa của "expensive" là?', 'options': ['costly', 'cheap', 'valuable', 'dear'], 'correctAnswer': 'cheap'},
    {'question': 'He is very ___ — he always tells the truth.', 'options': ['resilient', 'genuine', 'postpone', 'reluctant'], 'correctAnswer': 'genuine'},
    {'question': 'Từ "temporary" có nghĩa là gì?', 'options': ['Vĩnh viễn', 'Tạm thời', 'Nhanh chóng', 'Quan trọng'], 'correctAnswer': 'Tạm thời'},
    {'question': 'The weather is ___ today, very cold.', 'options': ['freezing', 'boiling', 'pleasant', 'resilient'], 'correctAnswer': 'freezing'},
    {'question': 'Từ nào trái nghĩa với "ancient"?', 'options': ['old', 'modern', 'historic', 'classic'], 'correctAnswer': 'modern'},
    {'question': 'Từ "negotiate" có nghĩa là gì?', 'options': ['Đàm phán, thương lượng', 'Từ chối', 'Đồng ý', 'Tranh luận'], 'correctAnswer': 'Đàm phán, thương lượng'},
    {'question': 'She ___ the job offer because it paid well.', 'options': ['accepted', 'refused', 'postponed', 'rejected'], 'correctAnswer': 'accepted'},
    {'question': 'Từ "vulnerable" có nghĩa là gì?', 'options': ['Mạnh mẽ', 'Dễ bị tổn thương', 'Kiên định', 'Độc lập'], 'correctAnswer': 'Dễ bị tổn thương'},
    {'question': 'The company ___ its employees for their hard work.', 'options': ['ignored', 'appreciated', 'criticized', 'disliked'], 'correctAnswer': 'appreciated'},
    {'question': 'Từ "comprehensive" có nghĩa là gì?', 'options': ['Toàn diện', 'Hạn chế', 'Đơn giản', 'Phức tạp'], 'correctAnswer': 'Toàn diện'},
    {'question': 'He has a ___ attitude towards learning.', 'options': ['negative', 'positive', 'reluctant', 'passive'], 'correctAnswer': 'positive'},
  ];

  final List<String?> _selectedAnswers = [];
  final List<Map<String, dynamic>> _questions = [];

  Timer? _timer;
  int _currentIndex = 0;
  int _secondsLeft = _totalSeconds;
  bool _questionsLoaded = false;
  bool _showResult = false;
  bool _isSavingResult = false;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadQuestions() {
    final provider = context.read<QuizProvider>();
    final source = provider.currentQuestions.isNotEmpty
        ? provider.currentQuestions
        : List<Map<String, dynamic>>.from(_fallbackQuestions)
          ..shuffle(Random(DateTime.now().millisecondsSinceEpoch));

    _questions
      ..clear()
      ..addAll(source.take(10));
    _selectedAnswers
      ..clear()
      ..addAll(List<String?>.filled(_questions.length, null));

    setState(() {
      _questionsLoaded = true;
    });
    _resetTimer();
  }

  // Fix: clean timer management — cancel old, only start new after state is set
  void _resetTimer() {
    _timer?.cancel();
    _secondsLeft = _totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        // Hết giờ → tự động chuyển câu
        _goNext();
        return;
      }
      setState(() {
        _secondsLeft--;
      });
    });
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswers[_currentIndex] = answer;
    });
  }

  void _goNext() {
    _timer?.cancel();
    if (_currentIndex >= _questions.length - 1) {
      _finishQuiz();
      return;
    }
    setState(() {
      _currentIndex++;
    });
    // Reset timer cho câu mới (timer sẽ start sau setState callback)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resetTimer();
    });
  }

  void _goPrev() {
    _timer?.cancel();
    if (_currentIndex <= 0) return;
    setState(() {
      _currentIndex--;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resetTimer();
    });
  }

  Future<void> _finishQuiz() async {
    final provider = context.read<QuizProvider>();
    final answers = <Map<String, dynamic>>[];

    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final selected = _selectedAnswers[i] ?? '';
      final correct = question['correctAnswer'] as String;
      answers.add({
        'question': question['question'],
        'options': question['options'],
        'selected': selected,
        'correct_answer': correct,
        'vocab_id': 'quiz_$i',
        'is_correct': selected == correct,
      });
    }

    setState(() {
      _isSavingResult = true;
    });

    await provider.submitQuiz(
      quizType: 'topic_quiz',
      answers: answers,
      topic: provider.selectedTopic,
    );

    if (mounted) {
      context.read<ProfileProvider>().recordActivity('quiz', xpEarned: _score * 10);
    }

    if (!mounted) return;
    setState(() {
      _isSavingResult = false;
      _showResult = true;
    });
  }

  int get _score {
    var correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['correctAnswer']) {
        correct++;
      }
    }
    return correct;
  }

  String get _formattedTime {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _timerProgress => _secondsLeft / _totalSeconds;

  @override
  Widget build(BuildContext context) {
    if (!_questionsLoaded || _isSavingResult) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isSavingResult ? 'Đang lưu kết quả...' : 'Đang tạo câu hỏi...',
                style: GoogleFonts.workSans(
                  fontSize: 15,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showResult) {
      return _buildResult();
    }

    return _buildQuiz();
  }

  Widget _buildQuiz() {
    final total = _questions.length;
    final item = _questions[_currentIndex];
    final options = (item['options'] as List).cast<String>();
    final selected = _selectedAnswers[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.go('/quiz'),
        ),
        title: Text(
          'Quiz theo chủ đề',
          style: GoogleFonts.workSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress + Timer
              Row(
                children: [
                  Text(
                    'Câu ${_currentIndex + 1}/$total',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (_currentIndex + 1) / total,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceSubtle,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Timer countdown bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _timerProgress,
                            minHeight: 3,
                            backgroundColor: AppColors.surfaceSubtle,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _secondsLeft <= 10 ? AppColors.danger : AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _secondsLeft <= 10
                          ? AppColors.dangerBg
                          : AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: _secondsLeft <= 10 ? AppColors.danger : AppColors.inkSoft,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formattedTime,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _secondsLeft <= 10 ? AppColors.danger : AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Question
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
                ),
                child: Text(
                  item['question'] as String,
                  style: GoogleFonts.workSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selected;
                    return InkWell(
                      onTap: () => _selectAnswer(option),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.blue.withValues(alpha: 0.08)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.blue
                                : AppColors.ink.withValues(alpha: 0.08),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.blue : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.blue
                                      : AppColors.ink.withValues(alpha: 0.16),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: GoogleFonts.workSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Navigation
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentIndex > 0 ? _goPrev : null,
                      child: const Text('Câu trước'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _goNext,
                      child: Text(
                        _currentIndex < total - 1 ? 'Câu tiếp theo' : 'Xem kết quả',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final total = _questions.length;
    final accuracy = total == 0 ? 0 : (_score / total * 100).round();
    final elapsed = DateTime.now().difference(_startedAt!).inSeconds;
    final minutes = (elapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsed % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.go('/quiz'),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accuracy >= 70
                      ? AppColors.successBg
                      : AppColors.dangerBg,
                ),
                child: Center(
                  child: Text(
                    '$accuracy%',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: accuracy >= 70 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                accuracy >= 70 ? 'Xuất sắc!' : 'Cố gắng hơn nhé!',
                style: GoogleFonts.workSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bạn đã hoàn thành bài quiz theo chủ đề.',
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _ResultBox(label: 'Đúng', value: '$_score/$total'),
                  const SizedBox(width: 10),
                  _ResultBox(label: 'XP', value: '+${_score * 10}'),
                  const SizedBox(width: 10),
                  _ResultBox(label: 'Thời gian', value: '$minutes:$seconds'),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết đáp án',
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(_questions.length, (index) {
                      final item = _questions[index];
                      final selected = _selectedAnswers[index] ?? 'Bỏ trống';
                      final correct = item['correctAnswer'] as String;
                      final isCorrect = selected == correct;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.successBg
                              : AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Câu ${index + 1}',
                              style: GoogleFonts.workSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bạn chọn: $selected',
                              style: GoogleFonts.workSans(
                                fontSize: 13,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            Text(
                              'Đáp án đúng: $correct',
                              style: GoogleFonts.workSans(
                                fontSize: 13,
                                color: isCorrect ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/quiz'),
                      child: const Text('Về trang chủ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 0;
                          _showResult = false;
                          _startedAt = DateTime.now();
                        });
                        _loadQuestions();
                      },
                      child: const Text('Làm lại'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final String label;
  final String value;

  const _ResultBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 12,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
