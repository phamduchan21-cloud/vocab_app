import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../models/mock_test.dart';
import '../services/mock_test_service.dart';
import '../services/api_service.dart';

class MockTestPlayScreen extends StatefulWidget {
  final String level;

  const MockTestPlayScreen({super.key, required this.level});

  @override
  State<MockTestPlayScreen> createState() => _MockTestPlayScreenState();
}

class _MockTestPlayScreenState extends State<MockTestPlayScreen> {
  final MockTestService _service = MockTestService(ApiService());

  MockTestSession? _session;
  int _currentIndex = 0;
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;

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
      final session = await _service.generate(widget.level);
      setState(() {
        _session = session;
        _secondsRemaining = session.durationMinutes * 60;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tạo đề thi. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _submitTest(force: true);
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _selectAnswer(int optionIndex) {
    if (_session == null) return;
    final answers = List<int?>.from(_session!.answers);
    answers[_currentIndex] = optionIndex;
    setState(() => _session = MockTestSession(
      id: _session!.id,
      level: _session!.level,
      questions: _session!.questions,
      total: _session!.total,
      durationMinutes: _session!.durationMinutes,
      answers: answers,
    ));
  }

  Future<void> _submitTest({bool force = false}) async {
    if (_session == null) return;
    _timer?.cancel();

    final unanswered = _session!.answers.where((a) => a == null).length;
    if (!force && unanswered > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nộp bài?', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          content: Text('Còn $unanswered câu chưa trả lời. Bạn có chắc muốn nộp bài?', style: GoogleFonts.nunito()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tiếp tục làm')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Nộp bài'),
            ),
          ],
        ),
      );
      if (confirm != true) {
        _startTimer();
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _service.submit(
        _session!.id,
        _session!.answers,
        _session!.questions,
      );
      if (mounted) {
        context.replace('/mock-test/result/${result.id}', extra: result);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi nộp bài: $e')),
        );
      }
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
        appBar: AppBar(title: const Text('Đang tạo đề...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: GoogleFonts.nunito()),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadTest, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    if (_session == null) return const SizedBox.shrink();

    final session = _session!;
    final answered = session.answers.where((a) => a != null).length;
    final progress = session.total > 0 ? answered / session.total : 0.0;
    final isTimeout = _secondsRemaining <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.level} · ${session.total} câu', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Thoát?', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              content: Text('Bài làm sẽ không được lưu.', style: GoogleFonts.nunito()),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ở lại')),
                ElevatedButton(onPressed: () { Navigator.pop(ctx); context.pop(); }, child: const Text('Thoát')),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: ClipRRect(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.catLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Đang nộp bài...')],
            ))
          : isTimeout
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_off, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Hết thời gian!', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () => _submitTest(force: true), child: const Text('Xem kết quả')),
                  ],
                ))
              : Column(
                  children: [
                    // Timer + Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, color: _secondsRemaining < 60 ? Colors.red : AppColors.textSecondary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(_secondsRemaining),
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _secondsRemaining < 60 ? Colors.red : AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text('$answered/${session.total}', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                        ],
                      ),
                    ),

                    // Question
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Câu ${_currentIndex + 1}/${session.total}',
                                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              session.questions[_currentIndex].question,
                              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 24),
                            ...List.generate(session.questions[_currentIndex].options.length, (i) {
                              final option = session.questions[_currentIndex].options[i];
                              final isSelected = session.answers[_currentIndex] == i;
                              return GestureDetector(
                                onTap: () => _selectAnswer(i),
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.3),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28, height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? AppColors.primary : Colors.transparent,
                                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.textHint),
                                        ),
                                        child: Center(child: Text(
                                          String.fromCharCode(65 + i),
                                          style: GoogleFonts.nunito(
                                            fontSize: 13, fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : AppColors.textSecondary,
                                          ),
                                        )),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(option, style: GoogleFonts.nunito(
                                          fontSize: 15, color: AppColors.textPrimary)),
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

                    // Bottom navigation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (_currentIndex > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => setState(() => _currentIndex--),
                                icon: const Icon(Icons.chevron_left, size: 20),
                                label: Text('Câu trước', style: GoogleFonts.nunito(fontSize: 14)),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          if (_currentIndex > 0) const SizedBox(width: 12),
                          Expanded(
                            child: _currentIndex < session.total - 1
                                ? ElevatedButton.icon(
                                    onPressed: () => setState(() => _currentIndex++),
                                    icon: const Icon(Icons.chevron_right, size: 20),
                                    label: Text('Câu sau', style: GoogleFonts.nunito(fontSize: 14)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () => _submitTest(),
                                    icon: const Icon(Icons.check_rounded, size: 20),
                                    label: Text('Nộp bài', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent3,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
