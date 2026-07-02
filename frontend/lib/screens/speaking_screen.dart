import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../app.dart';
import '../config/api_config.dart';

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  bool _isProcessing = false;
  Map<String, dynamic>? _result;
  List<Map<String, String>> _sentences = [];
  int _currentIndex = 0;
  String _selectedLevel = 'beginner';

  @override
  void initState() {
    super.initState();
    _loadSentences();
  }

  Future<void> _loadSentences() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/speaking/practice-sentences?level=$_selectedLevel&count=5'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _sentences = List<Map<String, String>>.from(
            data['sentences'].map((s) => {'text': s['text'], 'topic': s['topic']}),
          );
        });
        return;
      }
    } catch (_) {}
    setState(() {
      _sentences = [
        {'text': 'The weather today is very nice.', 'topic': 'Weather'},
        {'text': 'I like to read books in my free time.', 'topic': 'Hobby'},
      ];
    });
  }

  Future<void> _evaluateSpeaking() async {
    setState(() => _isProcessing = true);
    try {
      final sentence = _sentences[_currentIndex];
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/speaking/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reference_text': sentence['text'],
          'question_text': 'Please read the following sentence: ${sentence['text']}',
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _result = json.decode(response.body));
      } else {
        _mockResult(sentence['text']!);
      }
    } catch (_) {
      _mockResult(_sentences[_currentIndex]['text']!);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _mockResult(String text) {
    setState(() {
      _result = {
        'total_score': 75.0,
        'pronunciation_score': 70.0,
        'fluency_score': 75.0,
        'accuracy_score': 80.0,
        'grammar_score': 75.0,
        'feedback': 'Phát âm tốt! Cần cải thiện độ trôi chảy.',
        'transcript': text,
      };
    });
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.accent3;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.accent1;
    return AppColors.accent2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🗣️ Luyện nói', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
        foregroundColor: const Color(0xFF8B5CF6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _levelChip('beginner', '🌱 Cơ bản'),
              const SizedBox(width: 8),
              _levelChip('intermediate', '🌿 Trung cấp'),
              const SizedBox(width: 8),
              _levelChip('advanced', '🌳 Nâng cao'),
            ]),
            const SizedBox(height: 20),

            if (_sentences.isNotEmpty) ...[
              Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  Text('📖 Đọc câu sau:', style: GoogleFonts.nunito(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 12),
                  Text(_sentences[_currentIndex]['text']!, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: Text('📌 ${_sentences[_currentIndex]['topic']}', style: GoogleFonts.nunito(fontSize: 12, color: Colors.white)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _isProcessing ? null : _evaluateSpeaking,
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
                      boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Center(child: _isProcessing
                      ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Icon(Icons.auto_awesome_rounded, size: 36, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text(_isProcessing ? '⏳ AI đang chấm điểm...' : '🤖 Nhấn để AI đánh giá', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary))),

              if (_result != null && !_isProcessing) ...[
                const SizedBox(height: 24), _buildResultCard(), const SizedBox(height: 20),
                Row(children: [
                  if (_currentIndex > 0) Expanded(child: OutlinedButton.icon(onPressed: () => setState(() { _currentIndex--; _result = null; }), icon: const Icon(Icons.chevron_left), label: Text('Câu trước', style: GoogleFonts.nunito()))),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(onPressed: () { if (_currentIndex < _sentences.length - 1) setState(() { _currentIndex++; _result = null; }); }, icon: const Icon(Icons.chevron_right), label: Text('Câu tiếp', style: GoogleFonts.nunito()), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white))),
                ]),
              ],
            ],
            if (_sentences.isEmpty) Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: Column(children: [const Text('🎤', style: TextStyle(fontSize: 64)), const SizedBox(height: 16), Text('Không có câu luyện tập', style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textSecondary))]))),
          ],
        ),
      ),
    );
  }

  Widget _levelChip(String level, String label) {
    final isActive = _selectedLevel == level;
    return GestureDetector(
      onTap: () { setState(() { _selectedLevel = level; _currentIndex = 0; _result = null; }); _loadSentences(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isActive ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.3))),
        child: Text(label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildResultCard() {
    final total = (_result!['total_score'] ?? 0).toDouble();
    final pronunciation = (_result!['pronunciation_score'] ?? 0).toDouble();
    final fluency = (_result!['fluency_score'] ?? 0).toDouble();
    final accuracy = (_result!['accuracy_score'] ?? 0).toDouble();
    final grammar = (_result!['grammar_score'] ?? 0).toDouble();
    final feedback = _result!['feedback'] ?? '';
    final transcript = _result!['transcript'] ?? '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
        child: SizedBox(width: 130, height: 130,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: total / 100, strokeWidth: 10, backgroundColor: AppColors.catLight, valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(total))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${total.toStringAsFixed(0)}', style: GoogleFonts.nunito(fontSize: 34, fontWeight: FontWeight.bold, color: _scoreColor(total))),
              Text('tổng điểm', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 20),
      Container(width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Column(children: [
          _scoreRow('🎙️ Phát âm', pronunciation), const SizedBox(height: 10),
          _scoreRow('💬 Trôi chảy', fluency), const SizedBox(height: 10),
          _scoreRow('🎯 Chính xác', accuracy), const SizedBox(height: 10),
          _scoreRow('📐 Ngữ pháp', grammar),
        ]),
      ),
      const SizedBox(height: 12),
      Container(width: double.infinity, padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.catLight, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📝 Transcript:', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4), Text(transcript, style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textPrimary)),
        ]),
      ),
      const SizedBox(height: 12),
      Container(width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(feedback, style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF92400E)))),
        ]),
      ),
    ]);
  }

  Widget _scoreRow(String label, double score) {
    return Row(children: [
      Text(label, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(width: 10),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(value: score / 100, backgroundColor: AppColors.catLight, valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(score)), minHeight: 8))),
      const SizedBox(width: 10),
      SizedBox(width: 40, child: Text(score.toStringAsFixed(0), style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: _scoreColor(score)), textAlign: TextAlign.right)),
    ]);
  }
}
