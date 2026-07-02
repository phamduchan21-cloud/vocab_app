import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../providers/quiz_provider.dart';
import '../widgets/app_drawer.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().fetchCategories();
    });
  }

  Future<void> _startQuiz(QuizProvider quiz) async {
    await quiz.generateQuiz(count: 5);
    if (mounted) {
      if (quiz.currentQuestions.isNotEmpty) {
        context.go('/quiz/play');
      }
    }
  }

  final List<_QuizCategoryData> _categories = [
    _QuizCategoryData(
      icon: Icons.quiz_rounded,
      title: 'Chọn đáp án đúng',
      desc: 'Xem từ, chọn nghĩa đúng trong 4 đáp án',
      colors: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    ),
    _QuizCategoryData(
      icon: Icons.edit_rounded,
      title: 'Điền từ',
      desc: 'Xem nghĩa, gõ từ phù hợp',
      colors: const [Color(0xFFF472B6), Color(0xFFF9A8D4)],
    ),
    _QuizCategoryData(
      icon: Icons.translate_rounded,
      title: 'Nghĩa của từ',
      desc: 'Xem câu ví dụ, chọn nghĩa của từ',
      colors: const [Color(0xFFFB923C), Color(0xFFFBBF24)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn dạng bài')),
      drawer: const AppDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Bạn muốn luyện dạng nào?',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: GestureDetector(
                    onTap: quiz.isLoading ? null : () => _startQuiz(quiz),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: cat.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: cat.colors[0].withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(cat.icon, size: 32, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.title,
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.desc,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCategoryData {
  final IconData icon;
  final String title;
  final String desc;
  final List<Color> colors;

  const _QuizCategoryData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.colors,
  });
}
