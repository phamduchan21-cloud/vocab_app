import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../models/mock_test.dart';
import '../providers/profile_provider.dart';
import '../services/mock_test_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

class MockTestPlayScreen extends StatefulWidget {
  final String level;
  final String? topic;

  const MockTestPlayScreen({super.key, required this.level, this.topic});

  @override
  State<MockTestPlayScreen> createState() => _MockTestPlayScreenState();
}

class _MockTestPlayScreenState extends State<MockTestPlayScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _testId;
  List<MockTestQuestion> _questions = [];
  int _currentIndex = 0;
  final List<int?> _answers = [];
  int _secondsRemaining = 240;
  int _initialDurationSeconds = 240; // tổng thời gian cho phép (để tính _usedSeconds)
  Timer? _timer;
  bool _isSubmitted = false;
  bool _isSubmitting = false;

  // Results
  int _correctCount = 0;
  int _wrongCount = 0;
  int _scorePercent = 0;
  int _usedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = context.read<MockTestService>();
      final session = await service.generate(widget.level, widget.topic);
      _testId = session.id;
      _questions = session.questions;
      _secondsRemaining = session.durationMinutes * 60;
      _initialDurationSeconds = _secondsRemaining;
      _answers.addAll(List.filled(_questions.length, null));
      _isLoading = false;
      _startTimer();
      if (mounted) setState(() {});
    } catch (e) {
      _errorMessage = 'Không thể tạo đề kiểm tra. Vui lòng thử lại.';
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        _timer?.cancel();
        _submitTest();
        return;
      }
      if (mounted) setState(() => _secondsRemaining--);
    });
  }

  void _selectAnswer(int index) {
    if (_isSubmitted) return;
    setState(() => _answers[_currentIndex] = index);
  }

  void _goToQuestion(int index) {
    if (_isSubmitted) return;
    setState(() => _currentIndex = index);
  }

  void _goPrev() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _goNext() {
    if (_currentIndex < _questions.length - 1) setState(() => _currentIndex++);
  }

  String _calculateGrade(int percent) {
    if (percent >= 90) return 'A';
    if (percent >= 75) return 'B';
    if (percent >= 50) return 'C';
    return 'D';
  }

  String _englishLevel(int percent) {
    if (percent >= 90) return 'C1';
    if (percent >= 75) return 'B2';
    if (percent >= 60) return 'B1';
    if (percent >= 40) return 'A2';
    return 'A1';
  }

  Future<void> _submitTest() async {
    if (_isSubmitted || _isSubmitting) return;
    _timer?.cancel();
    _usedSeconds = _initialDurationSeconds - _secondsRemaining;

    _correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] != null &&
          _questions[i].options[_answers[i]!] == _questions[i].correctAnswer) {
        _correctCount++;
      }
    }
    _wrongCount = _questions.length - _correctCount;
    _scorePercent = (_correctCount * 100 ~/ _questions.length);

    if (mounted) {
      context.read<ProfileProvider>().recordActivity('quiz', xpEarned: _scorePercent);
    }

    setState(() => _isSubmitted = true);
  }

  Future<void> _submitToServer() async {
    if (_isSubmitting || _testId == null) return;
    _isSubmitting = true;
    if (mounted) setState(() {});

    try {
      final service = context.read<MockTestService>();
      final result = await service.submit(_testId!, _answers, _questions);
      if (!mounted) return;
      context.go('/mock-test/result/${result.id}', extra: result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu kết quả: $e')),
      );
      context.go('/test');
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: SkeletonLoading(type: SkeletonType.card)),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorStateWidget(
          message: _errorMessage!,
          onRetry: _loadTest,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isSubmitted ? _buildResults() : _buildTestLayout(),
      ),
    );
  }

  // ─── TEST LAYOUT (Responsive) ──────────────────────────────────────

  Widget _buildTestLayout() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 640;

    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: isMobile ? _buildMobileBody() : _buildTwoPanelBody(),
        ),
      ],
    );
  }

  // ─── MOBILE BODY ──────────────────────────────────────────────────

  Widget _buildMobileBody() {
    return Column(
      children: [
        // Compact horizontal question navigator
        _buildMobileNavigator(),
        // Current question card
        Expanded(child: _buildMobileQuestionCard()),
        // Footer with Prev / Next / Submit
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
            ),
          ),
          child: _buildFooter(),
        ),
      ],
    );
  }

  Widget _buildMobileNavigator() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Danh sách câu hỏi',
              style: GoogleFonts.workSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _questions.length,
              separatorBuilder: (_, i) => const SizedBox(width: 6),
              itemBuilder: (_, i) => _buildMobileQnavItem(i),
            ),
          ),
          const SizedBox(height: 6),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildMobileQnavItem(int index) {
    final isCurrent = index == _currentIndex;
    final isAnswered = _answers[index] != null;

    Color bg;
    Color border;
    Color textColor;
    double borderWidth;
    if (isCurrent) {
      bg = AppColors.blue;
      border = AppColors.blue;
      borderWidth = 2;
      textColor = Colors.white;
    } else if (isAnswered) {
      bg = AppColors.success.withValues(alpha: 0.12);
      border = AppColors.success;
      borderWidth = 1;
      textColor = AppColors.success;
    } else {
      bg = AppColors.surfaceSubtle;
      border = AppColors.ink.withValues(alpha: 0.14);
      borderWidth = 1;
      textColor = AppColors.inkSoft;
    }

    return GestureDetector(
      onTap: () => _goToQuestion(index),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: borderWidth),
        ),
        child: Center(
          child: Text('${index + 1}',
              style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ),
      ),
    );
  }

  Widget _buildMobileQuestionCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Câu ${_currentIndex + 1} / ${_questions.length}',
                style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.warning)),
            const SizedBox(height: 14),
            Text(_questions[_currentIndex].question,
                style: GoogleFonts.workSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.4)),
            const SizedBox(height: 22),
            ...List.generate(
                _questions[_currentIndex].options.length, (i) {
              final option = _questions[_currentIndex].options[i];
              final isSelected = _answers[_currentIndex] == i;
              return GestureDetector(
                onTap: () => _selectAnswer(i),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blue.withValues(alpha: 0.06)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.blue
                          : AppColors.ink.withValues(alpha: 0.14),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.blue
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.blue
                                : AppColors.ink
                                    .withValues(alpha: 0.14),
                          ),
                        ),
                        child: Center(
                          child:
                              Text(String.fromCharCode(65 + i),
                                  style: GoogleFonts.ibmPlexMono(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors
                                              .inkSoft)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(option,
                            style: GoogleFonts.workSans(
                                fontSize: 14,
                                color: AppColors.ink)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios,
                      size: 14, color: AppColors.inkSoft),
                  const SizedBox(width: 4),
                  Text('Trang chủ',
                      style: GoogleFonts.workSans(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mini-test',
                        style: GoogleFonts.workSans(
                            fontSize: 22, fontWeight: FontWeight.w600,
                            color: AppColors.ink)),
                    Text('Bài kiểm tra tổng hợp ${_questions.length} câu',
                        style: GoogleFonts.workSans(
                            fontSize: 13, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Text(_formatTime(_secondsRemaining),
                        style: GoogleFonts.ibmPlexMono(fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTwoPanelBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT: Navigator
        Container(
          width: 220,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Danh sách câu hỏi',
                  style: GoogleFonts.workSans(fontSize: 15,
                      fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 7,
                  crossAxisSpacing: 7,
                  childAspectRatio: 1,
                ),
                itemCount: _questions.length,
                itemBuilder: (_, i) => _buildQnavItem(i),
              ),
              const SizedBox(height: 16),
              _buildLegend(),
            ],
          ),
        ),
        // RIGHT: Quiz card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.ink.withValues(alpha: 0.14)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Câu ${_currentIndex + 1} / ${_questions.length}',
                              style: GoogleFonts.ibmPlexMono(fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2, color: AppColors.warning)),
                          const SizedBox(height: 14),
                          Text(_questions[_currentIndex].question,
                              style: GoogleFonts.workSans(fontSize: 20,
                                  fontWeight: FontWeight.w600, color: AppColors.ink,
                                  height: 1.4)),
                          const SizedBox(height: 26),
                          ...List.generate(
                              _questions[_currentIndex].options.length, (i) {
                            final option =
                                _questions[_currentIndex].options[i];
                            final isSelected = _answers[_currentIndex] == i;
                            return GestureDetector(
                              onTap: () => _selectAnswer(i),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.blue.withValues(alpha: 0.06)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.blue
                                        : AppColors.ink.withValues(alpha: 0.14),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26, height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? AppColors.blue : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.blue
                                              : AppColors.ink.withValues(alpha: 0.14),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(String.fromCharCode(65 + i),
                                            style: GoogleFonts.ibmPlexMono(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.inkSoft)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(option,
                                          style: GoogleFonts.workSans(
                                              fontSize: 15, color: AppColors.ink)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQnavItem(int index) {
    final isCurrent = index == _currentIndex;
    final isAnswered = _answers[index] != null;

    Color bg;
    Color border;
    double borderWidth;
    if (isCurrent) {
      bg = AppColors.surface; border = AppColors.blue; borderWidth = 2;
    } else if (isAnswered) {
      bg = AppColors.success.withValues(alpha: 0.12);
      border = AppColors.success; borderWidth = 1;
    } else {
      bg = AppColors.surfaceSubtle;
      border = AppColors.ink.withValues(alpha: 0.14); borderWidth = 1;
    }

    return GestureDetector(
      onTap: () => _goToQuestion(index),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: borderWidth),
          boxShadow: isCurrent
              ? [BoxShadow(color: AppColors.blue.withValues(alpha: 0.18), blurRadius: 4)]
              : null,
        ),
        child: Center(
          child: Text('${index + 1}',
              style: GoogleFonts.ibmPlexMono(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: isCurrent ? AppColors.ink
                      : isAnswered ? AppColors.success : AppColors.inkSoft)),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legendRow(AppColors.surfaceSubtle, AppColors.ink.withValues(alpha: 0.14), 'Chưa làm'),
        const SizedBox(height: 6),
        _legendRow(AppColors.success.withValues(alpha: 0.5), AppColors.success, 'Đã trả lời'),
        const SizedBox(height: 6),
        _legendRow(AppColors.surface, AppColors.blue, 'Đang xem'),
      ],
    );
  }

  Widget _legendRow(Color dotBg, Color dotBorder, String label) {
    return Row(
      children: [
        Container(width: 11, height: 11,
            decoration: BoxDecoration(
              color: dotBg, borderRadius: BorderRadius.circular(3),
              border: Border.all(color: dotBorder, width: 1.2))),
        const SizedBox(width: 7),
        Text(label,
            style: GoogleFonts.workSans(fontSize: 12, color: AppColors.inkSoft)),
      ],
    );
  }

  Widget _buildFooter() {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _questions.length - 1;
    final isMobile = MediaQuery.of(context).size.width < 640;

    if (isMobile) {
      return _buildMobileFooter(isFirst, isLast);
    }
    return _buildDesktopFooter(isFirst, isLast);
  }

  Widget _buildDesktopFooter(bool isFirst, bool isLast) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: isFirst ? null : _goPrev,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFirst
                    ? AppColors.ink.withValues(alpha: 0.06)
                    : AppColors.ink.withValues(alpha: 0.14),
              ),
              color: AppColors.surface,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left, size: 18,
                    color: isFirst ? AppColors.ink.withValues(alpha: 0.2) : AppColors.inkSoft),
                const SizedBox(width: 4),
                Text('Câu trước',
                    style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600,
                        color: isFirst ? AppColors.ink.withValues(alpha: 0.2) : AppColors.inkSoft)),
              ],
            ),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: isLast ? null : _goNext,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLast ? AppColors.ink.withValues(alpha: 0.06) : AppColors.ink.withValues(alpha: 0.14),
                  ),
                  color: AppColors.surface,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Câu sau',
                        style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600,
                            color: isLast ? AppColors.ink.withValues(alpha: 0.2) : AppColors.inkSoft)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18,
                        color: isLast ? AppColors.ink.withValues(alpha: 0.2) : AppColors.inkSoft),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _submitTest,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.blue,
                ),
                child: Text('Nộp bài',
                    style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFooter(bool isFirst, bool isLast) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: isFirst ? null : _goPrev,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFirst
                      ? AppColors.ink.withValues(alpha: 0.06)
                      : AppColors.ink.withValues(alpha: 0.14),
                ),
                color: AppColors.surface,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left, size: 18,
                      color: isFirst ? AppColors.ink.withValues(alpha: 0.2) : AppColors.inkSoft),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('Câu trước',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600,
                            color: isFirst ? AppColors.ink.withValues(alpha: 0.2) : AppColors.inkSoft)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: isLast ? null : _goNext,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLast ? AppColors.ink.withValues(alpha: 0.06) : AppColors.ink.withValues(alpha: 0.14),
                ),
                color: AppColors.surface,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text('Câu sau',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600,
                            color: isLast ? AppColors.ink.withValues(alpha: 0.2) : AppColors.inkSoft)),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18,
                      color: isLast ? AppColors.ink.withValues(alpha: 0.2) : AppColors.inkSoft),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _submitTest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.blue,
              ),
              child: Center(
                child: Text('Nộp bài',
                    style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── RESULTS ─────────────────────────────────────────────────────

  Widget _buildResults() {
    final grade = _calculateGrade(_scorePercent);
    final level = _englishLevel(_scorePercent);
    final isMobile = MediaQuery.of(context).size.width < 640;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 44,
        20,
        isMobile ? 16 : 44,
        60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.go('/test'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios, size: 14, color: AppColors.inkSoft),
                  const SizedBox(width: 4),
                  Text('Chọn cấp độ',
                      style: GoogleFonts.workSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ),

          // Stats
          isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _statCard('✓', '$_correctCount', 'Câu đúng', AppColors.success, 0.12)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('✕', '$_wrongCount', 'Câu sai', AppColors.danger, 0.10)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _statCard('%', '$_scorePercent%', 'Điểm số', AppColors.warning, 0.14)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('⏱', _formatTime(_usedSeconds), 'Thời gian', AppColors.blue, 0.10)),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _statCard('✓', '$_correctCount', 'Câu đúng', AppColors.success, 0.12)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('✕', '$_wrongCount', 'Câu sai', AppColors.danger, 0.10)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('%', '$_scorePercent%', 'Điểm số', AppColors.warning, 0.14)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('⏱', _formatTime(_usedSeconds), 'Thời gian', AppColors.blue, 0.10)),
                  ],
                ),
          const SizedBox(height: 16),

          // Grade & Level
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _scorePercent >= 75
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.12),
                    border: Border.all(
                      color: _scorePercent >= 75 ? AppColors.success : AppColors.warning,
                      width: 2,
                    ),
                  ),
                  child: Center(child: Text(grade,
                      style: GoogleFonts.workSans(fontSize: 22, fontWeight: FontWeight.w700,
                          color: _scorePercent >= 75 ? AppColors.success : AppColors.warning))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trình độ $level',
                          style: GoogleFonts.workSans(
                              fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      Text(_levelDescription(level),
                          style: GoogleFonts.workSans(fontSize: 13, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Answer review
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chi tiết đáp án',
                    style: GoogleFonts.workSans(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 16),
                ...List.generate(_questions.length, (i) {
                  final isCorrect = _answers[i] != null &&
                      _questions[i].options[_answers[i]!] == _questions[i].correctAnswer;
                  final chosenText = _answers[i] == null
                      ? 'Bỏ trống'
                      : _questions[i].options[_answers[i]!];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.workSans(fontSize: 14, color: AppColors.ink),
                              children: [
                                TextSpan(text: 'Câu ${i + 1}: ',
                                    style: GoogleFonts.workSans(fontWeight: FontWeight.w600)),
                                TextSpan(text: _questions[i].question),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? AppColors.success.withValues(alpha: 0.10)
                                : AppColors.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(chosenText,
                              style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isCorrect ? AppColors.success : AppColors.danger)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _isSubmitting ? null : _submitToServer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.blue,
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Lưu kết quả',
                              style: GoogleFonts.workSans(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.go('/test'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
                      color: AppColors.surface,
                    ),
                    child: Center(
                      child: Text('Về trang chọn đề',
                          style: GoogleFonts.workSans(
                              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: _isSubmitting ? null : _submitToServer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.blue,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Lưu kết quả',
                            style: GoogleFonts.workSans(
                                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.go('/test'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
                      color: AppColors.surface,
                    ),
                    child: Text('Về trang chọn đề',
                        style: GoogleFonts.workSans(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statCard(String icon, String value, String label, Color color, double alpha) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 30, height: 30,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: alpha), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(icon,
                  style: GoogleFonts.workSans(
                      fontSize: 14, fontWeight: FontWeight.w600, color: color)))),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.ibmPlexMono(
              fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.workSans(fontSize: 12, color: AppColors.inkSoft)),
        ],
      ),
    );
  }

  String _levelDescription(String level) {
    switch (level) {
      case 'C1': return 'Trình độ cao cấp — Có thể giao tiếp trôi chảy.';
      case 'B2': return 'Trình độ trung cao cấp — Giao tiếp tốt.';
      case 'B1': return 'Trình độ trung cấp — Giao tiếp cơ bản.';
      case 'A2': return 'Trình độ sơ cấp — Làm quen với ngôn ngữ.';
      default: return 'Trình độ mới bắt đầu — Bắt đầu hành trình.';
    }
  }
}
