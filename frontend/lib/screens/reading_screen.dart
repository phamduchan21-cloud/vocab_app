import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app.dart';
import '../config/api_config.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  List<Map<String, dynamic>> _types = [];
  Map<String, dynamic>? _progress;
  Map<String, dynamic>? _quiz;
  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  bool _isLoading = true;
  int _correctCount = 0;

  static const _typeColors = {
    'reading_subject': Color(0xFF3B82F6),
    'reading_grammar': Color(0xFFF472B6),
    'reading_content': Color(0xFF34D399),
    'reading_synonym': Color(0xFFFB923C),
    'reading_order': Color(0xFF8B5CF6),
    'reading_ad': Color(0xFFEF4444),
    'reading_passage': Color(0xFF14B8A6),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      final typesRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/reading/types'));
      final progressRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/reading/progress'));
      if (typesRes.statusCode == 200 && progressRes.statusCode == 200) {
        setState(() {
          _types = List<Map<String, dynamic>>.from(json.decode(typesRes.body)['types']);
          _progress = json.decode(progressRes.body);
          _isLoading = false;
        });
      } else { _mockData(); }
    } catch (_) { _mockData(); }
  }

  void _mockData() {
    setState(() {
      _isLoading = false;
      _types = [
        {'id': 'reading_subject', 'title': 'Chọn chủ đề', 'icon': '📌'},
        {'id': 'reading_grammar', 'title': 'Chọn ngữ pháp', 'icon': '✏️'},
        {'id': 'reading_content', 'title': 'Chọn nội dung', 'icon': '📋'},
        {'id': 'reading_synonym', 'title': 'Tìm đồng nghĩa', 'icon': '🔤'},
        {'id': 'reading_order', 'title': 'Chọn thứ tự', 'icon': '📑'},
        {'id': 'reading_ad', 'title': 'Đọc quảng cáo', 'icon': '📺'},
        {'id': 'reading_passage', 'title': 'Đoạn văn', 'icon': '📚'},
      ];
      _progress = {'completed': 2, 'correct_answers': 28, 'total_answers': 40, 'accuracy': 70.0};
    });
  }

  Future<void> _startQuiz(String type) async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/api/reading/generate?subtype=$type&count=5'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() { _quiz = data; _currentQuestion = 0; _selectedAnswer = null; _showResult = false; _correctCount = 0; _isLoading = false; });
        return;
      }
    } catch (_) {}
    setState(() {
      _quiz = {
        'questions': List.generate(5, (i) => {
          'question': 'Question ${i+1}: Choose the correct answer.',
          'options': ['Option A', 'Option B', 'Option C', 'Option D'],
          'correctAnswer': 'Option A',
        }), 'total': 5,
      };
      _currentQuestion = 0; _selectedAnswer = null; _showResult = false; _correctCount = 0; _isLoading = false;
    });
  }

  void _submitAnswer(int index) {
    final questions = _quiz!['questions'] as List;
    final isCorrect = questions[_currentQuestion]['options'][index] == questions[_currentQuestion]['correctAnswer'];
    setState(() { _selectedAnswer = index; if (isCorrect) _correctCount++; });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_currentQuestion < questions.length - 1) {
        setState(() { _currentQuestion++; _selectedAnswer = null; });
      } else { setState(() => _showResult = true); }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_quiz != null && !_showResult) return _buildQuiz();
    if (_showResult) return _buildResult();
    return Scaffold(
      appBar: AppBar(
        title: Text('📖 Đọc hiểu', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF34D399).withValues(alpha: 0.05),
        foregroundColor: const Color(0xFF34D399),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final p = _progress;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p != null)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF6EE7B7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('📝', '${p['completed']}', 'Bài đã làm'),
                  _statItem('✅', '${p['correct_answers']}', 'Câu đúng'),
                  _statItem('📈', '${p['accuracy']}%', 'Tỉ lệ đúng'),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text('📋 Chọn dạng bài:', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.3, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: _types.length,
            itemBuilder: (_, i) => _buildTypeCard(_types[i]),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: GoogleFonts.nunito(fontSize: 11, color: Colors.white70)),
    ]);
  }

  Widget _buildTypeCard(Map<String, dynamic> type) {
    final color = _typeColors[type['id']] ?? AppColors.primary;
    return GestureDetector(
      onTap: () => _startQuiz(type['id']),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(type['icon'] ?? '📝', style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(height: 8),
            Text(type['title'] ?? '', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final questions = _quiz!['questions'] as List;
    final q = questions[_currentQuestion];
    return Scaffold(
      appBar: AppBar(
        title: Text('❓ Câu ${_currentQuestion + 1}/${questions.length}', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF34D399).withValues(alpha: 0.05),
        foregroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _quiz = null; })),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_currentQuestion + 1) / questions.length,
                backgroundColor: AppColors.catLight,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text('$_correctCount/${_currentQuestion + (_selectedAnswer != null ? 1 : 0)} đúng', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            // Passage if exists
            if (q['passage'] != null) Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.catLight, borderRadius: BorderRadius.circular(12)),
              child: Text(q['passage'], style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
            ),
            if (q['passage'] != null) const SizedBox(height: 16),
            Text(q['question'] ?? '', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            ...List.generate((q['options'] as List).length, (i) {
              final option = q['options'][i];
              final isSelected = _selectedAnswer == i;
              final isCorrect = option == q['correctAnswer'];
              final isWrong = isSelected && !isCorrect;
              Color? optColor;
              if (_selectedAnswer != null) { optColor = isCorrect ? AppColors.accent3 : (isWrong ? AppColors.accent2 : null); }
              return GestureDetector(
                onTap: _selectedAnswer == null ? () => _submitAnswer(i) : null,
                child: Container(
                  width: double.infinity, margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: optColor?.withValues(alpha: 0.1) ?? (isSelected ? const Color(0xFF34D399).withValues(alpha: 0.1) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: optColor ?? (isSelected ? const Color(0xFF34D399) : const Color(0xFFE5E7EB)), width: isSelected ? 2 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? const Color(0xFF34D399) : Colors.transparent, border: Border.all(color: isSelected ? const Color(0xFF34D399) : AppColors.textHint)),
                      child: Center(child: Text(String.fromCharCode(65 + i), style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textSecondary))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(option, style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textPrimary))),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final total = (_quiz!['questions'] as List).length;
    final score = total > 0 ? (_correctCount / total * 100) : 0.0;
    return Scaffold(
      appBar: AppBar(
        title: Text('🎉 Kết quả', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text('${score.toStringAsFixed(0)}%', style: GoogleFonts.nunito(fontSize: 48, fontWeight: FontWeight.bold, color: score >= 80 ? AppColors.accent3 : AppColors.primary)),
              Text('$_correctCount/$total câu đúng', style: GoogleFonts.nunito(fontSize: 18, color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => setState(() { _quiz = null; _showResult = false; }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Về danh sách bài'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
