import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/quiz_provider.dart';
import '../widgets/question_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  Timer? _timer;
  int _secondsLeft = 30;
  bool _isSubmitting = false;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        _nextQuestion();
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _startTimer();
  }

  void _nextQuestion() {
    final quiz = context.read<QuizProvider>();
    if (_currentIndex < quiz.currentQuestions.length - 1) {
      _slideController.forward(from: 0);
      setState(() {
        _currentIndex++;
      });
      _resetTimer();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      _slideController.forward(from: 0);
      setState(() {
        _currentIndex--;
      });
      _resetTimer();
    }
  }

  Future<void> _submitQuiz() async {
    final quiz = context.read<QuizProvider>();
    final questions = quiz.currentQuestions;

    _timer?.cancel();
    setState(() => _isSubmitting = true);

    final answers = List<Map<String, dynamic>>.generate(
      questions.length,
      (i) => {
        'question': questions[i]['question'],
        'options': questions[i]['options'],
        'selected': _answers[i],
        'correctAnswer': questions[i]['correctAnswer'],
      },
    );

    await quiz.submitQuiz(
      quizType: 'Chọn đáp án đúng',
      answers: answers,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (quiz.lastResult != null) {
        context.push('/quiz/result/${quiz.lastResult!.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    if (quiz.isLoading && quiz.currentQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang chuẩn bị...')),
        body: const LoadingWidget(message: 'Đang tạo câu hỏi...'),
      );
    }

    if (quiz.errorMessage != null && quiz.currentQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: ErrorStateWidget(
          message: quiz.errorMessage!,
          onRetry: () => context.pop(),
        ),
      );
    }

    if (quiz.currentQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Không có câu hỏi nào')),
      );
    }

    final questions = quiz.currentQuestions;
    final currentQuestion = questions[_currentIndex];
    final isLastQuestion = _currentIndex == questions.length - 1;
    final progress = 'Câu ${_currentIndex + 1}/${questions.length}';

    return Scaffold(
      appBar: AppBar(
        title: Text(progress),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress + Timer bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                // Dots indicator
                Expanded(
                  child: Row(
                    children: List.generate(questions.length, (i) {
                      final isActive = i == _currentIndex;
                      final isAnswered = _answers.containsKey(i) && _answers[i] != null;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? AppColors.primary
                              : isAnswered
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : const Color(0xFFE5E7EB),
                        ),
                      );
                    }),
                  ),
                ),
                // Timer ring
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _secondsLeft / 30,
                        strokeWidth: 4,
                        backgroundColor: const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _secondsLeft <= 10 ? AppColors.accent2 : AppColors.primary,
                        ),
                      ),
                      Text(
                        '$_secondsLeft',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _secondsLeft <= 10 ? AppColors.accent2 : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Question
          Expanded(
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: QuestionCard(
                  key: ValueKey(_currentIndex),
                  question: currentQuestion['question'] as String,
                  options: (currentQuestion['options'] as List).cast<String>(),
                  selected: _answers[_currentIndex],
                  onSelected: (value) {
                    setState(() {
                      _answers[_currentIndex] = value;
                    });
                  },
                ),
              ),
            ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Câu trước'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 12),
                Expanded(
                  child: isLastQuestion
                      ? _buildSubmitButton()
                      : _buildNextButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final hasAnswer = _answers[_currentIndex] != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: hasAnswer ? AppTheme.primaryButtonGradient : null,
          color: hasAnswer ? null : const Color(0xFFE5E7EB),
        ),
        child: ElevatedButton(
          onPressed: hasAnswer ? _nextQuestion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: hasAnswer ? Colors.white : AppColors.textHint,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Câu sau', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final hasAllAnswers = _answers.length == context.read<QuizProvider>().currentQuestions.length;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: hasAllAnswers ? AppTheme.primaryButtonGradient : null,
          color: hasAllAnswers ? null : const Color(0xFFE5E7EB),
        ),
        child: ElevatedButton(
          onPressed: hasAllAnswers && !_isSubmitting ? _submitQuiz : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: hasAllAnswers ? Colors.white : AppColors.textHint,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Nộp bài', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle_rounded, size: 22),
                  ],
                ),
        ),
      ),
    );
  }
}
